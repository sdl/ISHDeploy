﻿using System.IO;
using ISHDeploy.Models;

namespace ISHDeploy.Business.Operations
{
    /// <summary>
    /// Provides absolute paths to all ISH files that are going to be used
    /// Also provides xpaths to XML elements and attributes in these files
    /// </summary>
    public partial class OperationPaths
    {
        /// <summary>
        /// The path to ~\Data\PublishingService\Tools\FeedSDLLiveContent.ps1.config
        /// </summary>
        public static class TemporarySTSConfigurationFileNames
        {
            /// <summary>
            /// The name of ISH WS certificate file
            /// </summary>
            public const string ISHWSCertificateFileName = "ishws.cer";

            /// <summary>
            /// The CM security token service template
            /// </summary>
            public const string CMSecurityTokenServiceTemplateFileName = "CM Security Token Service Requirements.md";
        }
    }
}
