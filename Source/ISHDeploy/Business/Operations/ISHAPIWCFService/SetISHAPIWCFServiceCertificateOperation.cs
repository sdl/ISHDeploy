﻿/**
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

using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceModel.Security;
using ISHDeploy.Business.Invokers;
using ISHDeploy.Data.Actions.Certificate;
using ISHDeploy.Data.Actions.DataBase;
using ISHDeploy.Data.Actions.File;
using ISHDeploy.Data.Actions.WebAdministration;
using ISHDeploy.Data.Actions.XmlFile;
using ISHDeploy.Interfaces;

namespace ISHDeploy.Business.Operations.ISHAPIWCFService
{
    /// <summary>
    /// Sets WCF service to use a certificate that matches to thumbprint
    /// </summary>
    /// <seealso cref="IOperation" />
    public class SetISHAPIWCFServiceCertificateOperation : BasePathsOperation, IOperation
	{
		/// <summary>
		/// The actions invoker
		/// </summary>
		private readonly IActionInvoker _invoker;

        /// <summary>
        /// Initializes a new instance of the class.
        /// </summary>
        /// <param name="logger">The logger.</param>
        /// <param name="ishDeployment">The instance of the deployment.</param>
        /// <param name="thumbprint">The certificate thumbprint.</param>
        /// <param name="validationMode">The certificate validation mode.</param>
        public SetISHAPIWCFServiceCertificateOperation(ILogger logger, Models.ISHDeployment ishDeployment, string thumbprint, X509CertificateValidationMode validationMode) :
            base(logger, ishDeployment)
		{
			_invoker = new ActionInvoker(logger, "Setting of Thumbprint and issuers values to configuration");

            var normalizedThumbprint = new string(thumbprint.ToCharArray().Where(char.IsLetterOrDigit).ToArray());

		    if (normalizedThumbprint.Length != thumbprint.Length)
		    {
                logger.WriteWarning($"The thumbprint '{thumbprint}' has been normalized to '{normalizedThumbprint}'");
		        thumbprint = normalizedThumbprint;
            }

            // Ensure DataBase file exists
            _invoker.AddAction(new SqlCompactEnsureDataBaseExistsAction(logger, InfoShareSTSDataBase.Path.AbsolutePath, $"{ISHDeploymentInternal.BaseUrl}/{ISHDeploymentInternal.STSWebAppName}"));
            _invoker.AddAction(new FileWaitUnlockAction(logger, InfoShareSTSDataBase.Path));

            // Update STS database
            var parameters = new List<object> { string.Empty };
            parameters.Add(string.Join(", ", InfoShareSTSDataBase.SvcPaths));

            _invoker.AddAction(new GetEncryptedRawDataByThumbprintAction(logger, thumbprint, result => parameters[0] = result));

            _invoker.AddAction(new SqlCompactUpdateAction(logger,
                InfoShareSTSDataBase.ConnectionString,
                InfoShareSTSDataBase.UpdateCertificateSQLCommandFormat,
                parameters));

            // Stop STS Application pool before updating RelyingParties 
            _invoker.AddAction(new StopApplicationPoolAction(logger, ISHDeploymentInternal.STSAppPoolName));

            // thumbprint
            _invoker.AddAction(new SetAttributeValueAction(logger, InfoShareAuthorWebConfig.Path, InfoShareAuthorWebConfig.CertificateReferenceFindValueAttributeXPath, thumbprint));
            _invoker.AddAction(new SetAttributeValueAction(logger, InfoShareSTSConfig.Path, InfoShareSTSConfig.CertificateThumbprintAttributeXPath, thumbprint));
            _invoker.AddAction(new SetAttributeValueAction(logger, InfoShareWSWebConfig.Path, InfoShareWSWebConfig.CertificateThumbprintXPath, thumbprint));

            // validationMode
            _invoker.AddAction(new SetAttributeValueAction(logger, FeedSDLLiveContentConfig.Path, FeedSDLLiveContentConfig.InfoShareWSServiceCertificateValidationModeAttributeXPath, validationMode.ToString()));
            _invoker.AddAction(new SetAttributeValueAction(logger, TranslationOrganizerConfig.Path, TranslationOrganizerConfig.InfoShareWSServiceCertificateValidationModeAttributeXPath, validationMode.ToString()));
            _invoker.AddAction(new SetAttributeValueAction(logger, SynchronizeToLiveContentConfig.Path, SynchronizeToLiveContentConfig.InfoShareWSServiceCertificateValidationModeAttributeXPath, validationMode.ToString()));
            _invoker.AddAction(new SetElementValueAction(logger, TrisoftInfoShareClientConfig.Path, TrisoftInfoShareClientConfig.InfoShareWSServiceCertificateValidationModeXPath, validationMode.ToString()));
            _invoker.AddAction(new SetElementValueAction(logger, InfoShareWSConnectionConfig.Path, InfoShareWSConnectionConfig.InfoShareWSServiceCertificateValidationModeXPath, validationMode.ToString()));


            // Recycling Application pool for STS
            _invoker.AddAction(new RecycleApplicationPoolAction(logger, ISHDeploymentInternal.STSAppPoolName, true));

            // Waiting until files becomes unlocked
            _invoker.AddAction(new FileWaitUnlockAction(logger, InfoShareSTSWebConfig.Path));
        }

        /// <summary>
        /// Runs current operation.
        /// </summary>
        public void Run()
		{
			_invoker.Invoke();
            Logger.WriteWarning("This cmdlet modified the cookie encryption. All existing browser and client sessions must be recreated.");
        }
    }
}
