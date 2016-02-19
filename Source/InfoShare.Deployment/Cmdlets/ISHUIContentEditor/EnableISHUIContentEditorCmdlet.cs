﻿using System.Management.Automation;
using InfoShare.Deployment.Business.CmdSets.ISHUIContentEditor;
using InfoShare.Deployment.Providers;
using InfoShare.Deployment.Business;

namespace InfoShare.Deployment.Cmdlets.ISHUIContentEditor
{
    [Cmdlet(VerbsLifecycle.Enable, CmdletNames.ISHUIContentEditor, SupportsShouldProcess = false)]
    public sealed class EnableISHUIContentEditorCmdlet : BaseHistoryEntryCmdlet
    {
        [Parameter(Mandatory = false, Position = 0)]
        [Alias("proj")]
        [ValidateNotNull]
        public Models.ISHDeployment ISHDeployment { get; set; }

        protected override string HistoryEntry => $"{VerbsLifecycle.Enable}-{CmdletNames.ISHUIContentEditor}";

        protected override string DeploymentSuffix => (ISHDeployment ?? ISHProjectProvider.Instance.ISHDeployment).Suffix;

        public override void ExecuteCmdlet()
        {
            var ishPaths = new ISHPaths(ISHDeployment ?? ISHProjectProvider.Instance.ISHDeployment);

            var cmdSet = new EnableISHUIContentEditorCmdSet(Logger, ishPaths);

            cmdSet.Run();
        }
    }
}