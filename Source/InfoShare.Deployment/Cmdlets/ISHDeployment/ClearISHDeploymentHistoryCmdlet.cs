﻿using System.Management.Automation;
using InfoShare.Deployment.Business;
using InfoShare.Deployment.Data.Managers.Interfaces;
using InfoShare.Deployment.Extensions;

namespace InfoShare.Deployment.Cmdlets.ISHDeployment
{
    /// <summary>
    /// <para type="synopsis">Clears customization history for Content Manager deployment.</para>
    /// <para type="description">The Clear-ISHDeploymentHistory cmdlet clears customization history information for Content Manager deployment that was generated by other cmdlets.</para>
    /// <para type="link">Get-ISHDeployment</para>
    /// <para type="link">Get-ISHDeploymentHistory</para>
    /// <para type="link">Undo-ISHDeployment</para>
    /// </summary>
    /// <example>
    /// <code>PS C:\>Clear-ISHDeploymentHistory -ISHDeployment $deployment</code>
    /// <para>This command clears the history information for Content Manager deployment.
    /// Parameter $deployment is an instance of the Content Manager deployment retrieved from Get-ISHDeployment cmdlet.</para>
    /// </example>
    [Cmdlet(VerbsCommon.Clear, "ISHDeploymentHistory")]
    public class ClearISHDeploymentHistoryCmdlet : BaseCmdlet
    {
        /// <summary>
        /// <para type="description">Specifies the instance of the Content Manager deployment.</para>
        /// </summary>
        [Parameter(Mandatory = true, HelpMessage = "Instance of the installed Content Manager deployment.")]
        public Models.ISHDeployment ISHDeployment { get; set; }
        
        /// <summary>
        /// Executes cmdlet
        /// </summary>
        public override void ExecuteCmdlet()
        {
            var fileManager = ObjectFactory.GetInstance<IFileManager>();
            var ishPaths = new ISHPaths(ISHDeployment);

			// Remove history file
			var historyFilePath = ishPaths.HistoryFilePath;
	        if (fileManager.Exists(historyFilePath))
	        {
		        fileManager.Delete(historyFilePath);
	        }

			// Clean backup directory
			var backupFolderPath = ISHDeployment.GetDeploymentBackupFolder();
	        fileManager.CleanFolder(backupFolderPath);
		}
	}
}
