﻿using System.IO;
using InfoShare.Deployment.Business.Invokers;
using InfoShare.Deployment.Data;
using InfoShare.Deployment.Data.Commands.XmlFileCommands;
using InfoShare.Deployment.Interfaces;
using InfoShare.Deployment.Models;

namespace InfoShare.Deployment.Business.CmdSets.ISHUIQualityAssistant
{
    public class EnableISHUIQualityAssistantCmdSet : ICmdSet
    {
        private readonly CommandInvoker _invoker;

		private readonly string[] _uncommentPatterns = { CommentPatterns.EnrichIntegration };

        public EnableISHUIQualityAssistantCmdSet(ILogger logger, ISHProject ishProject)
        {
			_invoker = new CommandInvoker(logger, "InfoShare Enrich integration for Create");

			_invoker.AddCommand(new XmlUncommentCommand(logger, Path.Combine(ishProject.AuthorFolderPath, ISHPaths.EnrichConfig), _uncommentPatterns));
			_invoker.AddCommand(new XmlUncommentCommand(logger, Path.Combine(ishProject.AuthorFolderPath, ISHPaths.XopusConfig), _uncommentPatterns));
		}

        public void Run()
        {
            _invoker.Invoke();
        }
    }
}
