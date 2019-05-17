using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Hammond.Models
{

        public class CloneJob
        {
            public string Dataset { get; set; }
            public bool IsSatelliteDC { get; set; }
            public string SourceDC { get; set; }
            public string Requestor { get; set; }
            public string Reason { get; set; }
            public string WebUser { get; set; }
        }

        public class CloneJobXMLFile
        {
            public string FileName { get; set; }
        }
}
