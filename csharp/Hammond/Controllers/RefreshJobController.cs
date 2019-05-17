using System;
using Microsoft.AspNetCore.Mvc;
using Hammond.Models;
using System.Net.Mail;
using System.Xml.Linq;


namespace Hammond.Controllers
{
    public class RefreshJob : Controller
    {
        public IActionResult RefreshJobForm()
        {
            return View();
        }

        [HttpGet]
        public IActionResult ReviewXML()
        {
            //construct path to search for XML files
            string RootDir = Environment.CurrentDirectory.ToString();
            string OutputDir = RootDir + "/output/";

            //get the XML files in the specified location
            string[] XMLfiles;
            XMLfiles = System.IO.Directory.GetFiles(OutputDir, "*.xml");

            //clean up the file path information for display on the view
            foreach (string XMLfile in XMLfiles)
            {
                int i = Array.IndexOf(XMLfiles, XMLfile);
                XMLfiles[i] = XMLfile.Split("/")[2];
            }

            //set the view data and return the view
            ViewData["FileArray"] = XMLfiles;

            return View();

        }

        [HttpPost, ValidateAntiForgeryToken]
        public IActionResult RemoveXML(CloneJobXMLFile xf)
        {
            //construct path for XML files
            string RootDir = Environment.CurrentDirectory.ToString();
            string OutputDir = RootDir + "/output/";
            string FullFilePath = OutputDir + xf.FileName;

            //DELETE the XML files in the specified location
            System.IO.File.Delete(FullFilePath);

            ViewData["DeletedFile"] = xf.FileName;
            return View();
        }

        [HttpPost, ValidateAntiForgeryToken]
        public IActionResult Index(CloneJob job)
        {
            //set WebUser value on the job object so they can be notified by the job processing script
            //this also tells me who was authenticated, if someone submits a job and enters a false name in
            //the Requestor field
            job.WebUser = User.Identity.Name;

            //set boolean value for IsSatelliteDC
            if(job.Dataset == "Satellite-DEVSQL1" || job.Dataset == "Satellite-DEVSQL2") { job.IsSatelliteDC = true; }
            else { job.IsSatelliteDC = false; };

            //send properties of NewUser model to View data for confirmation to the enduser
            ViewData["Dataset"] = "Dataset: " + job.Dataset;
            ViewData["IsSatelliteDC"] = "Is Satellite: " + job.IsSatelliteDC;
            ViewData["SourceDC"] = "Source DC: " + job.SourceDC;
            ViewData["Requestor"] = "Requestor: " + job.Requestor;
            ViewData["Reason"] = "Reason for Refresh: " + job.Reason;

            //send notification to Operations for recordkeeping purposes
            NotifyISOps(job);

            //write the data to an importable XML file for PowerShell script to do its thing
            WriteDataToXMLFile(job);

            //display the submitted values back to the enduser
            return View("~/Views/RefreshJob/Results.cshtml");

        }

        private void NotifyISOps(CloneJob job)
        {
            //declare variables relevant to this process
            string SmtpServerAddress = "mail.demo-corp.com";
            string RecipientAddress = "dba@demo-corp.com";
            string ReturnAddress = "automailer@demo-corp.com";

            //define message object and properties

            //define client object
            SmtpClient client = new SmtpClient(SmtpServerAddress);

            //define sending address and display name
            MailAddress from = new MailAddress(ReturnAddress, "Hammond Auto Mailer", System.Text.Encoding.UTF8);

            //define recipient address
            MailAddress to = new MailAddress(RecipientAddress);

            //define the message object
            MailMessage message = new MailMessage(from, to);

            //set message object properties
            message.Body = "<html><strong>The following job data was submitted for a clone dataset refresh using the Hammond WebApp.</strong><br/><br/>Dataset: " + job.Dataset + "<br/>Is Satellite: " + job.IsSatelliteDC + "<br/>Source DC: " + job.SourceDC + "<br/>Requestor: " + job.Requestor + "<br/>Reason: " + job.Reason + "<br/>WebUser:" + job.WebUser;
            message.BodyEncoding = System.Text.Encoding.UTF8;
            message.IsBodyHtml = true;
            message.Subject = "New job submitted on Hammond WebApp";
            message.SubjectEncoding = System.Text.Encoding.UTF8;

            //send the message
            client.Send(message);

            //dispose of the message object
            message.Dispose();

        }

        private void WriteDataToXMLFile(CloneJob job)
        {
            //construct paths and file name
            string RequestDate = DateTime.Now.ToShortDateString().Replace('/','.');

            string RootDir = Environment.CurrentDirectory.ToString();
            string OutputDir = RootDir + "/output/";
            string FilePath = OutputDir + job.Dataset.Replace(" ","") + "." + job.Requestor.Replace(" ", "") + "." + RequestDate + ".xml";

            //create directory if it does not exist and then write a blank file
            System.IO.Directory.CreateDirectory(OutputDir);
            System.IO.File.WriteAllText(FilePath, "");

            //create the xml writer object and define
            XDocument xo = new XDocument(

                //create parent element UserData
                new XElement("JobData",

                            //create child elements for properties that will be used to create the user
                            new XElement("Dataset", job.Dataset),
                            new XElement("IsSatelliteDC", job.IsSatelliteDC),
                            new XElement("SourceDC", job.SourceDC),
                            new XElement("Requestor", job.Requestor),
                            new XElement("Reason", job.Reason),
                            new XElement("WebUser", job.WebUser)

                            ) //close UserData element

                ); //end XDocument definition

            //save file
            xo.Save(FilePath);


        }
    }
}
