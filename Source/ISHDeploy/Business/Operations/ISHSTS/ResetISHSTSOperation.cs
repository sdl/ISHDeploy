/*
 * Copyright (c) 2014 All Rights Reserved by the SDL Group.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
using ISHDeploy.Business.Invokers;
using ISHDeploy.Business.Operations.ISHComponent;
using ISHDeploy.Common.Enums;
using ISHDeploy.Data.Actions.File;
using ISHDeploy.Common.Interfaces;
using Models = ISHDeploy.Common.Models;

namespace ISHDeploy.Business.Operations.ISHSTS
{
    /// <summary>
    /// Resets STS database
    /// </summary>
    /// <seealso cref="IOperation" />
    public class ResetISHSTSOperation : BaseOperationPaths, IOperation
	{
		/// <summary>
		/// The actions invoker
		/// </summary>
		public IActionInvoker Invoker { get; }

        /// <summary>
        /// Initializes a new instance of the class.
        /// </summary>
        /// <param name="logger">The logger.</param>
        /// <param name="ishDeployment">The instance of the deployment.</param>
        public ResetISHSTSOperation(ILogger logger, Models.ISHDeployment ishDeployment) :
            base(logger, ishDeployment)
		{
			Invoker = new ActionInvoker(logger, "Reset STS database");

            var stoptOperation = new StopISHComponentOperation(Logger, ishDeployment, ISHComponentName.STS);
            Invoker.AddActionsRange(stoptOperation.Invoker.GetActions());

            Invoker.AddAction(new FileCleanDirectoryAction(logger, WebNameSTSAppData));

            var startOperation = new StartISHComponentOperation(Logger, ishDeployment, ISHComponentName.STS);
            Invoker.AddActionsRange(startOperation.Invoker.GetActions());

            Invoker.AddAction(new FileWaitUnlockAction(logger, InfoShareSTSWebConfigPath));
        }

		/// <summary>
		/// Runs current operation.
		/// </summary>
		public void Run()
		{
			Invoker.Invoke();
		}
	}
}
