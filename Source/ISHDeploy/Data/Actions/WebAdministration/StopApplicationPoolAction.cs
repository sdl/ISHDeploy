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
using ISHDeploy.Data.Managers.Interfaces;
using ISHDeploy.Interfaces;
using ISHDeploy.Interfaces.Actions;

namespace ISHDeploy.Data.Actions.WebAdministration
{
    /// <summary>
    /// Stops an application pool.
    /// </summary>
    /// <seealso cref="SingleFileCreationAction" />
    public class StopApplicationPoolAction : BaseAction, IRestorableAction
    {
        /// <summary>
        /// The Application Pool name.
        /// </summary>
        private readonly string _appPoolName;

        /// <summary>
        /// The web Administration manager
        /// </summary>
        private readonly IWebAdministrationManager _webAdminManager;

        /// <summary>
        /// Initializes a new instance of the <see cref="StopApplicationPoolAction"/> class.
        /// </summary>
        /// <param name="logger">The logger.</param>
        /// <param name="appPoolName">Name of the application pool.</param>
        public StopApplicationPoolAction(ILogger logger, string appPoolName)
            : base(logger)
        {
            _appPoolName = appPoolName;

            _webAdminManager = ObjectFactory.GetInstance<IWebAdministrationManager>();
        }

        /// <summary>
        /// Executes current action.
        /// </summary>
        public override void Execute()
        {
            _webAdminManager.StopApplicationPool(_appPoolName);
        }

        /// <summary>
        /// Creates backup of the asset.
        /// </summary>
        public void Backup()
        {

        }

        /// <summary>
        /// Reverts an asset to initial state.
        /// </summary>
        public void Rollback()
        {
            _webAdminManager.RecycleApplicationPool(_appPoolName, true);

            // Add Sleep to wait until pool will free all files
            System.Threading.Thread.Sleep(7000);
        }
    }
}
