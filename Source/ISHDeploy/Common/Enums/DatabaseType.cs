﻿/*
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
namespace ISHDeploy.Common.Enums
{
    /// <summary>
    /// <para type="description">Enumeration listing the supported database types.</para>
    /// </summary>
    public enum DatabaseType
    {
        /// <summary>
        /// Used to initialize the enum
        /// </summary>
        None,
        /// <summary>
        /// Oracle RDBMS, including 9.2.0.2, 9.2.0.4, 9.2.0.6, 10.1.0.4, 10.2.0.2
        /// </summary>
        oracle,
        /// <summary>
        /// Microsoft SqlServer 2012
        /// </summary>
        sqlserver2012,
        /// <summary>
        /// Microsoft SqlServer 2014
        /// </summary>
        sqlserver2014
    }
}
