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
﻿using ISHDeploy.Common.Interfaces;
using ISHDeploy.Common.Models;

namespace ISHDeploy.Data.Actions.XmlFile
{
    /// <summary>
    /// Action that removes single node in xml file found by xpaths.
    /// </summary>
    /// <seealso cref="SingleXmlFileAction" />
    public class RemoveSingleNodeAction : SingleXmlFileAction
    {
        /// <summary>
        /// The xpath to the xml node.
        /// </summary>
        private readonly string _xpath;

        /// <summary>
        /// Output warnings or not.
        /// </summary>
        private readonly bool _outputWarnings;

        /// <summary>
        /// Initializes a new instance of the <see cref="RemoveSingleNodeAction"/> class.
        /// </summary>
        /// <param name="logger">The logger.</param>
        /// <param name="filePath">The xml file path.</param>
        /// <param name="xpath">The xpath to the node that needs to be removed.</param>
        /// <param name="outputWarnings">Output warnings or not. Is true by default</param>
        public RemoveSingleNodeAction(ILogger logger, ISHFilePath filePath, string xpath, bool outputWarnings = true)
			: base(logger, filePath)
        {
            _xpath = xpath;
            _outputWarnings = outputWarnings;
        }

        /// <summary>
        /// Executes current action.
        /// </summary>
        public override void Execute()
        {
			XmlConfigManager.RemoveSingleNode(FilePath, _xpath, _outputWarnings);
        }
    }
}
