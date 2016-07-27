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
﻿using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using ISHDeploy.Data.Managers.Interfaces;
using ISHDeploy.Interfaces;

namespace ISHDeploy.Data.Managers
{
    /// <summary>
    /// Generates documents from resource templates.
    /// </summary>
    /// <seealso cref="ITemplateManager" />
    public class TemplateManager : ITemplateManager
    {
        /// <summary>
        /// The templates resource folder.
        /// </summary>
        private const string TemplateBaseFolder = "ISHDeploy.Data.Resources.Templates";

        /// <summary>
        /// The logger.
        /// </summary>
        private readonly ILogger _logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="TemplateManager"/> class.
        /// </summary>
        /// <param name="logger">The logger.</param>
        public TemplateManager(ILogger logger)
        {
            _logger = logger;
        }

        /// <summary>
        /// Generate output document from the template.
        /// </summary>
        /// <param name="templateFileName">Name of the template file.</param>
        /// <param name="parameters">All parameters that need to be filled out in the template.</param>
        /// <returns></returns>
        public string GenerateDocument(string templateFileName, IDictionary<string, string> parameters)
        {
            string templateFile = $"{TemplateBaseFolder}.{templateFileName}";
            string templateContent;

            _logger.WriteDebug($"Reading the resource template: {templateFile}");
            using (var resourceReader = Assembly.GetExecutingAssembly().GetManifestResourceStream(templateFile))
            {
                using (var reader = new StreamReader(resourceReader))
                {
                    templateContent = reader.ReadToEnd();
                }
            }

            _logger.WriteDebug("Replacing all parameters in template: " + string.Join("; ", parameters.Select(param => $"{param.Key}={param.Value}").ToArray()));
            templateContent = parameters.Aggregate(templateContent, (current, parameter) => current.Replace(parameter.Key, parameter.Value));

            return templateContent;
        }
    }
}
