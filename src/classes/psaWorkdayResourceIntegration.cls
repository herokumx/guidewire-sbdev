/**************************************************************************************
// Name          : psaWorkdayIntegration
// Date          : April 8, 2015
// Description   : Contains methods related to the Workday integration including creating
//                  and updating Resources and Users and also PTO requests
// Author        : CLD Partners
// Revisions     : 2015-04-08  Klassen  Initial version
//               : 2015-06-08 Spano Update -- add Legal first/last names
//               : 2015-07-08  Klassen  Don't require User Manager or Contact Practice 
//                  if the Dept is a non PS Dept 
***************************************************************************************/
public with sharing class psaWorkdayResourceIntegration {
    public psaWorkdayResourceIntegration() {}

    /**************************************************************************************
    // Name         : processPSAResources
    // Description  : Create or update salesforce contacts ("Resources") based on a set of 
    //                  PSA Resource Stage Ids.
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 2015-07-08  Klassen  Don't require Practice if the Dept is a non PS Dept
    ***************************************************************************************/
    public static void processPSAResources(Set<Id> resourceStageIds) {
        Map<String, Contact> resourceMap;
        Map<Id, PSA_Resource_Stage__c> resourceStageMap;
        Map<String, PSA_Resource_Practice__c> resourcePracticeMap = new Map<String, PSA_Resource_Practice__c>();
        Map<String, pse__Region__c> regionMap = new Map<String, pse__Region__c>();
        Map<String, pse__Work_Calendar__c> workCalendarMap = new Map<String, pse__Work_Calendar__c>();
        List<Contact> resourcesToUpdate = new List<Contact>();
        List<Contact> resourcesToAdd = new List<Contact>();
        Set<String> workerIds = new Set<String>();
        Map<String, PSA_Department__c> departmentMap = new Map<String, PSA_Department__c>();

        //Get the map and list of Stage records
        resourceStageMap = new Map<Id, PSA_Resource_Stage__c>(
            [Select CurrencyIsoCode, Id, PSA_Legal_First_Name__c, PSA_Legal_Last_Name__c, PSA_Absence_End_Date__c, PSA_Absence_Start_Date__c, PSA_Change_Effective_Date__c, PSA_City__c, PSA_Company_Name__c, 
                    PSA_Contingent_Worker_Type__c, PSA_Country__c, PSA_Department__c, PSA_Email__c, PSA_Entity_Id__c, PSA_First_Name__c, PSA_GW_Integration_Id__c, 
                    PSA_Hire_Date__c, PSA_Last_Name__c, PSA_Manager__c, PSA_Mobile_Phone__c, PSA_Partner_Name_Id__c, PSA_Phone__c, PSA_Postal_Code__c, PSA_Processed__c, 
                    PSA_Processed_Date__c, PSA_Product_Line_ID__c, PSA_PS_Level__c, PSA_Resource_Status__c, PSA_State_Province__c, 
                    PSA_Termination_Date__c, PSA_Time_Zone__c, PSA_Title__c, PSA_WD_Region_ID__c, PSA_WD_Work_Calendar_Name__c, PSA_Worker_Id__c, PSA_Worker_Type__c 
                From PSA_Resource_Stage__c
                Where Id In :resourceStageIds
            ]);
        System.debug('*** resource stages: '+resourceStageMap);
        List<PSA_Resource_Stage__c> resourceStageList = resourceStageMap.values();

        //*** BEGIN Populate Maps
        for (PSA_Resource_Stage__c resourceStage : resourceStageList) {
            workerIds.add(resourceStage.PSA_Worker_Id__c);
            resourceStage.PSA_Processed__c = true;
            resourceStage.PSA_Processed_Date__c = DateTime.now();
        }

        // SOQL to look up Resources and Users associated with each PSA Resource Stage record
        resourceMap = new Map<String, Contact>();
        List<Contact> resources = 
            [Select Id, pse__Region__c, pse__Work_Calendar__c, PSA_Legal_First_Name__c, PSA_Legal_Last_Name__c, FirstName, LastName, PSA_Resource_Entity__c, PSA_Resource_Department__c, 
                    PSA_Absence_Start_Date__c, PSA_Absence_End_Date__c, Email, PSA_Company_Name__c, PSA_Contingent_Worker_Type__c, 
                    PSA_Worker_Type__c, PSA_Hire_Date__c, PSA_PS_Level__c, PSA_Product_Line_ID__c, MailingCity, MailingCountry, 
                    MailingState, MailingPostalCode, CurrencyIsoCode, PSA_Termination_Date__c, pse__External_Resource__c, PSA_Worker_Id__c, 
                    PSA_Resource_Stage__c, PSA_Resource_Stage__r.PSA_GW_Integration_Id__c, PSA_Home_Country__c, PSA_Home_State__c, 
                    MobilePhone, Phone  
                From Contact
                Where PSA_Worker_Id__c In :workerIds
            ];

        System.debug('*** Contacts: '+resources);
        for (Contact resource : resources) {
            resourceMap.put(resource.PSA_Worker_Id__c, resource);
        }

        //Populate a map of PSA Resource Practice records which are needed to update the Practice on Resources
        String mapKey;
        List<PSA_Resource_Practice__c> resourcePractices = 
            [Select Id, PSA_Practice__c, PSA_Department__r.PSA_Department_Code__c, PSA_Entity__r.PSA_Entity_Code__c
                From PSA_Resource_Practice__c               
            ];
        for (PSA_Resource_Practice__c resourcePractice : resourcePractices) {
            mapKey = resourcePractice.PSA_Department__r.PSA_Department_Code__c + ':' + resourcePractice.PSA_Entity__r.PSA_Entity_Code__c;
            resourcePracticeMap.put(mapKey, resourcePractice);
        }

        //Populate a map of Region records which are needed to update the Region on Resources
        List<pse__Region__c> regions = 
            [Select Id, PSA_WD_Region_ID__c
                From pse__Region__c
            ];
        for (pse__Region__c region : regions) {
            regionMap.put(region.PSA_WD_Region_ID__c, region);
        }

        //Populate a map of Work Calendar records which are needed to update the Work Calendar on Resources
        List<pse__Work_Calendar__c> workCalendars = 
            [Select Id, PSA_WD_Work_Calendar_Name__c
                From pse__Work_Calendar__c
            ];
        for (pse__Work_Calendar__c workCalendar : workCalendars) {
            workCalendarMap.put(workCalendar.PSA_WD_Work_Calendar_Name__c, workCalendar);
        }

        //Populate a map of Department records which are needed to update the Department on Resources
        List<PSA_Department__c> departments = 
            [Select Id, PSA_Department_Code__c, PSA_PS_Department__c
                From PSA_Department__c
            ];
        for (PSA_Department__c department : departments) {
            departmentMap.put(department.PSA_Department_Code__c, department);
        }
        //*** END Populate Maps

        //*** BEGIN Create/Update Resources
        Contact updatedResource;
        for (PSA_Resource_Stage__c resourceStage : resourceStageList) {
            if (!verifyResourceExists(resourceStage.PSA_Worker_Id__c, resourceMap)) {
                updatedResource = createOrUpdateResource(resourceStage, true, resourcePracticeMap, 
                    regionMap, workCalendarMap, resourceMap, departmentMap);
                if (updatedResource != null) {
                    resourcesToAdd.add(updatedResource);
                }
            } else {
                updatedResource = createOrUpdateResource(resourceStage, false, resourcePracticeMap, 
                    regionMap, workCalendarMap, resourceMap, departmentMap);
                if (updatedResource != null) {
                    resourcesToUpdate.add(updatedResource);         
                }
            }
        }
        //*** END Create/Update Resources

        //*** BEGIN DML operations
        Contact resource;
        Database.SaveResult sr;

        //Updated Resources
        Database.SaveResult[] srList = Database.Update(resourcesToUpdate, false);
        for (Integer i = 0; i< resourcesToUpdate.size(); i++) {
            sr = srList[i];
            resource = resourcesToUpdate[i];
            PSA_Resource_Stage__c resourceStage = resourceStageMap.get(resource.PSA_Resource_Stage__c);         
            if (sr.isSuccess() == true) {
                System.debug('Successfully Updated Resource.  ResourceId: ' + resource.Id + ' - ResourceStageId:' + resource.PSA_Resource_Stage__c);

                //Write an entry to the Integration Log
                String logMessage = 'Successfully updated resource';
                psaIntegrationUtils.writeLogEntry(resourceStage.Id, 'Resource', psaIntegrationUtils.INTERGRATION_TYPE_UPDATED_RESOURCE, 
                    psaIntegrationUtils.LOG_TYPE_INFORMATION, logMessage, null, resourceStage.PSA_GW_Integration_Id__c, resource.Id);
            } else {
                // Operation failed, so get all errors
                psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), true, resourceStage.Id, 
                    psaIntegrationUtils.INTERGRATION_TYPE_UPDATED_RESOURCE, 'Resource', resource.Id);
            }
        }

        //Added Resources
        srList = Database.Insert(resourcesToAdd, false);
        for (Integer i = 0; i< resourcesToAdd.size(); i++) {
            sr = srList[i];
            resource = resourcesToAdd[i];
            PSA_Resource_Stage__c resourceStage = resourceStageMap.get(resource.PSA_Resource_Stage__c);         
            if (sr.isSuccess() == true) {
                System.debug('Successfully Inserted Resource.  ResourceId: ' + resource.Id + ' - ResourceStageId:' + resource.PSA_Resource_Stage__c);

                //Write an entry to the Integration Log
                String logMessage = 'Successfully inserted resource';
                psaIntegrationUtils.writeLogEntry(resourceStage.Id, 'Resource', psaIntegrationUtils.INTERGRATION_TYPE_NEW_RESOURCE, 
                    psaIntegrationUtils.LOG_TYPE_INFORMATION, logMessage, null, resourceStage.PSA_GW_Integration_Id__c, resource.Id);
            } else {
                // Operation failed, so get all errors
                psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), true, resourceStage.Id, 
                    psaIntegrationUtils.INTERGRATION_TYPE_NEW_RESOURCE, 'Resource', null);
            }
        }

        //Update the Processed and Processed Date fields
        update resourceStageList;

        //BEGIN Integration Log Update
        //  Update the gw integration id in the integration log where applicable
        psaIntegrationUtils.updateGWIds('Resource');
        //END update the reference id and gw integration id in the integration log where applicable

        //*** END DML operations
    }

    /**************************************************************************************
    // Name         : processPSAUsers
    // Description  : Create or update salesforce users based on a set of PSA Resource Stage Ids.
    //                  Uses @future annotation because User record dml operations can't be 
    //                  mixed with "non-Setup" salesforce objects
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 2015-07-08  Klassen  Don't require Manager if the Dept is a non PS Dept
    ***************************************************************************************/
    @future 
    public static void processPSAUsers(Set<Id> resourceStageIds) {
        Map<String, User> userMap;
        List<User> usersToUpdate = new List<User>();
        List<User> usersToAdd = new List<User>();
        Set<String> workerIds = new Set<String>();
        Map<String, PSA_Department__c> departmentMap = new Map<String, PSA_Department__c>();

        List<PSA_Resource_Stage__c> resourceStageList = 
            [Select CurrencyIsoCode, Id, PSA_Absence_End_Date__c, PSA_Legal_First_Name__c, PSA_Legal_Last_Name__c, PSA_Absence_Start_Date__c, PSA_Change_Effective_Date__c, PSA_City__c, PSA_Company_Name__c, 
                    PSA_Contingent_Worker_Type__c, PSA_Country__c, PSA_Department__c, PSA_Email__c, PSA_Entity_Id__c, PSA_First_Name__c, PSA_GW_Integration_Id__c, 
                    PSA_Hire_Date__c, PSA_Last_Name__c, PSA_Manager__c, PSA_Mobile_Phone__c, PSA_Partner_Name_Id__c, PSA_Phone__c, PSA_Postal_Code__c, PSA_Processed__c, 
                    PSA_Processed_Date__c, PSA_Product_Line_ID__c, PSA_PS_Level__c, PSA_Resource_Status__c, PSA_State_Province__c, 
                    PSA_Termination_Date__c, PSA_Time_Zone__c, PSA_Title__c, PSA_WD_Region_ID__c, PSA_WD_Work_Calendar_Name__c, PSA_Worker_Id__c, PSA_Worker_Type__c
                From PSA_Resource_Stage__c
                Where Id In :resourceStageIds
            ];
            
        //*** BEGIN Populate Maps
        for (PSA_Resource_Stage__c resourceStage : resourceStageList) {
            workerIds.add(resourceStage.PSA_Worker_Id__c);
        }

        // SOQL to look up Resources and Users associated with each PSA Resource Stage record
        userMap = new Map<String, User>();
        List<User> users = 
            [Select Id, Name, PSA_Worker_Id__c
                From User
                Where PSA_Worker_Id__c In :workerIds
            ];
        for (User usr : users) {
            userMap.put(usr.PSA_Worker_Id__c, usr);
        }

        //Populate a map of Department records which are needed to determine if a manager is required
        List<PSA_Department__c> departments = 
            [Select Id, PSA_Department_Code__c, PSA_PS_Department__c
                From PSA_Department__c
            ];
        for (PSA_Department__c department : departments) {
            departmentMap.put(department.PSA_Department_Code__c, department);
        }
        //*** END Populate Maps


        //*** BEGIN Create/Update Users
        for (PSA_Resource_Stage__c resourceStage : resourceStageList) {
            if (!verifyUserExists(resourceStage.PSA_Worker_Id__c, userMap)) {
                usersToAdd.add(createOrUpdateUser(resourceStage, true, departmentMap));
            } else {
                usersToUpdate.add(createOrUpdateUser(resourceStage, false, departmentMap));
            }
        }
        //*** END Create/Update Users


        //*** BEGIN DML operations
        User usr;
        Database.SaveResult sr;

        Database.SaveResult[] srList = Database.Update(usersToUpdate, false);
        for (Integer i = 0; i< usersToUpdate.size(); i++) {
            sr = srList[i];
            usr = usersToUpdate[i];
            if (sr.isSuccess() == true) {
                System.debug('Successfully Updated user.  UserId: ' + usr.Id + ' - ResourceStageId:' + usr.PSA_Resource_Stage__c);
            } else {
                // Operation failed, so get all errors
                psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), false, usr.PSA_Resource_Stage__c, 
                    psaIntegrationUtils.INTERGRATION_TYPE_UPDATED_RESOURCE, 'User', usr.Id);
            }
        }

        srList = Database.Insert(usersToAdd, false);
        for (Integer i = 0; i< usersToAdd.size(); i++) {
            sr = srList[i];
            usr = usersToAdd[i];
            if (sr.isSuccess() == true) {
                System.debug('Successfully Inserted user.  UserId: ' + usr.Id + ' - ResourceStageId:' + usr.PSA_Resource_Stage__c);
            } else {
                // Operation failed, so get all errors
                psaIntegrationUtils.logDatabaseErrors(sr.getErrors(), false, usr.PSA_Resource_Stage__c, 
                    psaIntegrationUtils.INTERGRATION_TYPE_NEW_RESOURCE, 'User', null);
            }
        }
        //*** END DML operations

        scheduleUpdateUser();

    }

    /**************************************************************************************
    // Name         : verifyResourceExists
    // Description  : If a Resource (Contact) does not exist for the Worker Id, return
    //                  false, else return true
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    private static Boolean verifyResourceExists(String workerId, Map<String, Contact> resourceMap) {
        Boolean resourceExists = true;
        if (resourceMap == null) {
            resourceExists = false;
        } else {
            Contact resource = resourceMap.get(workerId);
            if (resource == null) {
                resourceExists = false;
            }
        }
        return resourceExists;
    }

    /**************************************************************************************
    // Name         : verifyUserExists
    // Description  : If a User does not exist for the Worker Id, return
    //                  false, else return true
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    private static Boolean verifyUserExists(String workerId, Map<String, User> userMap) {
        Boolean userExists = true;
        if (userMap == null) {
            userExists = false;
        } else {
            User usr = userMap.get(workerId);
            if (usr == null) {
                userExists = false;
            }
        }
        return userExists;
    }

    /**************************************************************************************
    // Name         : createOrUpdateResource
    // Description  : If a Resource (Contact) does not exist for the Worker Id, create a new
    //                  Resource.  This should trigger notifications to Ops and PSA Admin.
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 2015-07-08  Klassen  Don't require Practice if the Dept is a non PS Dept
    ***************************************************************************************/
    private static Contact createOrUpdateResource(PSA_Resource_Stage__c resourceStage, Boolean newResource, 
            Map<String, PSA_Resource_Practice__c> resourcePracticeMap, Map<String, pse__Region__c> regionMap, 
            Map<String, pse__Work_Calendar__c> workCalendarMap, Map<String, Contact> resourceMap, 
            Map<String, PSA_Department__c> departmentMap) {

        //Populate Address Country and State maps which will be used to standardize the state and country values
        Map<String, pw_cc__CountryObject__c> homeCountryMap = new Map<String, pw_cc__CountryObject__c>();
        Map<String, pw_cc__State__c> homeStateMap = new Map<String, pw_cc__State__c>();
        //Populate the address Country map
        List<pw_cc__CountryObject__c> homeCountryList = 
            [Select Id, Name, pw_cc__IsoCode_2__c
                From pw_cc__CountryObject__c
                Where pw_cc__Enabled__c = true
            ];
        for (pw_cc__CountryObject__c country : homeCountryList) {
            homeCountryMap.put(country.pw_cc__IsoCode_2__c, country);
        }

        //Populate the address State(/Province) map
        String mapKey;
        List<pw_cc__State__c> homeStateList =
            [Select Id, Name, pw_cc__Country__c, pw_cc__IsoCode__c, pw_cc__Country__r.pw_cc__IsoCode_2__c 
                From pw_cc__State__c
                Where pw_cc__IsDeleted__c = false
                And pw_cc__Country__r.pw_cc__IsoCode_2__c In ('US', 'CA')
            ];
        for (pw_cc__State__c state : homeStateList) {
            mapKey = state.pw_cc__Country__r.pw_cc__IsoCode_2__c + ':' + state.pw_cc__IsoCode__c;
            homeStateMap.put(mapKey, state);
        }

        //Logic added to prevent errors from occuring if the integration department doesn't exist
        // which could happen if the resource is a Transfer Out
        Boolean isPSDepartment = getIsPSDepartment(resourceStage, departmentMap);
        PSA_Department__c department;
        Id departmentId;
        if (resourceStage.PSA_Department__c != null) {
            department = departmentMap.get(resourceStage.PSA_Department__c);
            if (department != null) {
                departmentId = department.Id;
            }
        }

        Contact resource;
        try {
            if (newResource == true) {
                resource = new Contact();
                resource.PSA_Worker_Id__c = resourceStage.PSA_Worker_Id__c;
                resource.AccountId = getResourceAccount(resourceStage);
                resource.pse__Is_Resource__c = true;
                resource.RecordTypeId = [Select Id From RecordType Where DeveloperName = 'PSA_Resource'].Id;
                resource.pse__Group__c = getGroup(resourceStage);
                resource.FirstName = resourceStage.PSA_First_Name__c;
                resource.Email = resourceStage.PSA_Email__c;
            } else {
                resource = resourceMap.get(resourceStage.PSA_Worker_Id__c);
            }
            
            if (resourceStage.PSA_Resource_Status__c == 'Active' && resourceStage.PSA_PS_Level__c != null) {
                resource.pse__Is_Resource_Active__c = true;
            } else {
                resource.pse__Is_Resource_Active__c = false;
            }
            if (resourceStage.PSA_Worker_Type__c != 'Employee') {
                resource.pse__External_Resource__c = true;
            }

            resource.CurrencyIsoCode = resourceStage.CurrencyIsoCode;
            resource.pse__Region__c = getResourceRegionId(resourceStage.PSA_WD_Region_ID__c, resourceStage, newResource, regionMap);
            resource.pse__Work_Calendar__c = getResourceWorkCalendarId(resourceStage.PSA_WD_Work_Calendar_Name__c, resourceStage, newResource, workCalendarMap);
            resource.pse__Practice__c = getPractice(resourceStage, newResource, resourcePracticeMap, isPSDepartment);
            resource.PSA_Resource_Stage__c = resourceStage.Id;
            resource.LastName = resourceStage.PSA_Last_Name__c;
            resource.PSA_Resource_Entity__c = [Select Id From PSA_Entity__c Where PSA_Entity_Code__c =:resourceStage.PSA_Entity_Id__c].Id;
            resource.PSA_Resource_Department__c = departmentId; //[Select Id From PSA_Department__c Where PSA_Department_Code__c =: resourceStage.PSA_Department__c].Id;
            resource.PSA_Absence_Start_Date__c = resourceStage.PSA_Absence_Start_Date__c;
            resource.PSA_Absence_End_Date__c = resourceStage.PSA_Absence_End_Date__c;
            resource.Title = resourceStage.PSA_Title__c;
            resource.PSA_Company_Name__c = resourceStage.PSA_Company_Name__c;
            resource.PSA_Contingent_Worker_Type__c = resourceStage.PSA_Contingent_Worker_Type__c;
            resource.PSA_Worker_Type__c = resourceStage.PSA_Worker_Type__c;
            resource.PSA_Hire_Date__c = resourceStage.PSA_Hire_Date__c;
            resource.PSA_PS_Level__c = resourceStage.PSA_PS_Level__c;
            resource.PSA_Product_Line_ID__c = resourceStage.PSA_Product_Line_ID__c;
            resource.MailingCity = resourceStage.PSA_City__c;
            resource.MailingCountry = resourceStage.PSA_Country__c;
            resource.MailingState = resourceStage.PSA_State_Province__c;
            resource.MailingPostalCode = resourceStage.PSA_Postal_Code__c;
            resource.PSA_Termination_Date__c = resourceStage.PSA_Termination_Date__c;
            resource.PSA_Legal_First_Name__c = resourceStage.PSA_Legal_First_Name__c;
            resource.PSA_Legal_Last_Name__c = resourceStage.PSA_Legal_Last_Name__c;
            resource.MobilePhone = resourceStage.PSA_Mobile_Phone__c;
            resource.Phone = resourceStage.PSA_Phone__c;

            //Set the Home State and Home Country fields
            pw_cc__CountryObject__c homeCountry;
            if (resourceStage.PSA_Country__c != null) {
                homeCountry = homeCountryMap.get(resourceStage.PSA_Country__c);
                if (homeCountry != null) {
                    resource.PSA_Home_Country__c = homeCountry.Id;
                    resource.MailingCountry = homeCountry.Name;
                }
            }
            if (resourceStage.PSA_State_Province__c != null && homeCountry != null && (resourceStage.PSA_Country__c == 'US' || resourceStage.PSA_Country__c == 'CA')) {
                mapKey = resourceStage.PSA_Country__c + ':' + resourceStage.PSA_State_Province__c;
                pw_cc__State__c homeState = homeStateMap.get(mapKey);
                if (homeState != null) {
                    resource.PSA_Home_State__c = homeState.Id;
                    resource.MailingState = homeState.Name;
                }
            }

            //If the PS Level is blank, add a warning log message
            if (resourceStage.PSA_PS_Level__c == null) {
                //Write an entry to the Integration Log
                String logMessage = 'Missing PS Level for resource worker Id: ' + resourceStage.PSA_Worker_Id__c;
                String integrationType;
                if (newResource) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_RESOURCE; }
                else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_UPDATED_RESOURCE; }
                Id resourceId;
                if (!newResource) {resourceId = resource.Id; }

                psaIntegrationUtils.writeLogEntry(resourceStage.Id, 'Resource', integrationType, 
                            psaIntegrationUtils.LOG_TYPE_WARNING, logMessage, null, 
                            resourceStage.PSA_GW_Integration_Id__c, resourceId);
            }
        } catch (Exception e) {
            //Write an entry to the Integration Log
            String logMessage = e.getLineNumber() + ' : ' + e.getMessage();
            String integrationType;
            if (newResource) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_RESOURCE; }
            else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_UPDATED_RESOURCE; }
            Id resourceId;
            if (!newResource) {resourceId = resource.Id; }

            psaIntegrationUtils.writeLogEntry(resourceStage.Id, 'Resource', integrationType, 
                        psaIntegrationUtils.LOG_TYPE_ERROR, logMessage, e.getStackTraceString(), 
                        resourceStage.PSA_GW_Integration_Id__c, resourceId);
            return null;            
        }

        //setDefaultResourceValues(resourceStage, )
        return resource;
    }

 
    /**************************************************************************************
    // Name         : createOrUpdateUser
    // Description  : If a User does not exist for the Worker Id, create a new
    //                  User.  If the User record exists, update it.
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 2015-07-08  Klassen  Don't require Manager if the Dept is a non PS Dept
    ***************************************************************************************/
    private static User createOrUpdateUser(PSA_Resource_Stage__c resourceStage, Boolean newUser, 
            Map<String, PSA_Department__c> departmentMap) {
        User usr;
        if (newUser == true) {
            usr = new User();
            
            string aliasFirst ='';
            string aliasLast='';
            
            if (resourceStage.PSA_First_Name__c != null || resourceStage.PSA_First_Name__c != '' )
               aliasFirst = aliasFirst + resourceStage.PSA_First_Name__c.substring(0,1);

            if (resourceStage.PSA_Last_Name__c.length() > 4)                
               aliasLast = aliasLast + resourceStage.PSA_Last_Name__c.substring(0,4);
            else if (resourceStage.PSA_Last_Name__c.length() <= 4)              
               aliasLast = aliasLast + resourceStage.PSA_Last_Name__c;
            
            usr.Alias = aliasFirst + aliasLast;
            
            usr.PSA_Worker_Id__c = resourceStage.PSA_Worker_Id__c;
        //    usr.Alias = resourceStage.PSA_First_Name__c.substring(0,1) + resourceStage.PSA_Last_Name__c.substring(0,4);
            usr.CommunityNickname = getNickname(resourceStage);
            usr.FederationIdentifier = resourceStage.PSA_Email__c;
            usr.Email = resourceStage.PSA_Email__c;
            usr.UserName = resourceStage.PSA_Email__c;
            usr.TimeZoneSidKey = getUserTimeZone(resourceStage.PSA_Time_Zone__c);
            usr.FirstName = resourceStage.PSA_First_Name__c;
            setDefaultUserValues(usr);
        } else {
            usr =   
                [Select Id, PSA_Worker_Id__c, Email, UserName, TimeZoneSidKey, FirstName, LastName, ManagerId, MobilePhone, Phone, 
                        Title, city, Country, State, PostalCode, CommunityNickname, FederationIdentifier, PSA_Resource_Stage__c, 
                        ProfileId  
                    From User
                    Where PSA_Worker_Id__c =: resourceStage.PSA_Worker_Id__c
                ];

            System.debug('current user profile Id: ' + usr.ProfileId);
            //If the user has a chatter free user profile, update them to the default user profile based on the PSA
            // Integration custom setting Default User Profile
            PSA_Integration__c psaIntegration = PSA_Integration__c.getValues('default');
            if (psaIntegration == null) {
                Throw new psaException('Missing the "default" PSA Integration custom setting');
            } else {
                String chatterUserProfileName = 'Chatter Free User';
                Id chatterUserProfileId = [Select Id From Profile Where Name =: chatterUserProfileName].Id;
                System.debug('chatter free user profile Id: ' + chatterUserProfileId);
                if (usr.ProfileId == chatterUserProfileId) {
                    usr.ProfileId = [Select Id From Profile Where Name =: psaIntegration.PSA_Default_User_Profile__c].Id;
                }
            }
        }

        if (resourceStage.PSA_Resource_Status__c == 'Active') {
            usr.IsActive = true;
        } else {
            usr.IsActive = false;
        }

        //Logic added to prevent errors from occuring if the Manager doesn't exist
        // which could happen if the resource is a Transfer Out
        Boolean isPSDepartment = getIsPSDepartment(resourceStage, departmentMap);

        usr.CurrencyIsoCode = resourceStage.CurrencyIsoCode;
        usr.PSA_Resource_Stage__c = resourceStage.Id;
        usr.LastName = resourceStage.PSA_Last_Name__c;
        usr.ManagerId = getManagerId(resourceStage.PSA_Manager__c, isPSDepartment);
        usr.MobilePhone = resourceStage.PSA_Mobile_Phone__c;
        usr.Phone = resourceStage.PSA_Phone__c;
        usr.Title = resourceStage.PSA_Title__c;
        usr.City = resourceStage.PSA_City__c;
        usr.Country = resourceStage.PSA_Country__c;
        usr.State = resourceStage.PSA_State_Province__c;
        usr.PostalCode = resourceStage.PSA_Postal_Code__c;

        return usr;
    }
 
    /**************************************************************************************
    // Name         : getNickname
    // Description  : Get a value for the Nickname field.  Might need to autoincrement a suffix
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    private static String getNickname(PSA_Resource_Stage__c resourceStage) {
        Integer emailNameIndex = resourceStage.PSA_Email__c.indexOf('@');
        return resourceStage.PSA_Email__c.left(emailNameIndex);     
    }
 
    /**************************************************************************************
    // Name         : getManagerId
    // Description  : Look up the Manager Id from the User object based on the Worker Id
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 2015-07-08  Klassen  Don't require Manager if the Dept is a non PS Dept
    ***************************************************************************************/
    private static Id getManagerId(String managerWorkerId, Boolean isPSDepartment) {
        Id managerId;
        List<User> managerUser = [Select Id From User Where PSA_Worker_Id__c =:managerWorkerId];
        if (managerUser != null && managerUser.size() > 0) {
            managerId = managerUser[0].Id;
        }
        if (managerId == null && isPSDepartment == true) {
            Throw new psaException('Unable to find the Manager User based on the Worker Id: ' + managerWorkerId);
        }
        return managerId;
    }
 
    /**************************************************************************************
    // Name         : getUserTimeZone
    // Description  : Look up the SF timezone from the PSA Time Zone custom object which  
    //                  maps the Workday timezone value to the SF timezone value
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    private static String getUserTimeZone(String sourceTimeZone) {
        String salesforceTimeZone = '';
        List<PSA_Time_Zone__c> timezone = [Select PSA_Salesforce_Time_Zone__c
                From PSA_Time_Zone__c
                Where PSA_Workday_Time_Zone__c =: sourceTimeZone
                LIMIT 1
            ];
            
        if (timezone == null || timezone.isEmpty()) {
            Throw new psaException('Missing the Workday Time Zone record');
        } else {
            salesforceTimeZone = timezone.get(0).PSA_Salesforce_Time_Zone__c;
        }
        return salesforceTimeZone;
    }
 
    /**************************************************************************************
    // Name         : setDefaultUserValues
    // Description  : Set various default values for new Users.  This will include reading
    //                  some values in the PSA Integration Custom Settings object.
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    private static void setDefaultUserValues(User newUser) {
        PSA_Integration__c psaIntegration = PSA_Integration__c.getValues('default');
        if (psaIntegration == null) {
            Throw new psaException('Missing the "default" PSA Integration custom setting');
        } else {
            newUser.EmailEncodingKey = psaIntegration.PSA_Default_Email_Encoding__c;
            newUser.LanguageLocaleKey = psaIntegration.PSA_Default_Language__c;
            newUser.LocaleSidKey = psaIntegration.PSA_Default_Locale__c;
            newUser.UserRoleId = [Select Id From UserRole Where Name =: psaIntegration.PSA_Default_Role__c].Id;
//          newUser. = psaIntegration.PSA_Default_User_License__c;
            newUser.ProfileId = [Select Id From Profile Where Name =: psaIntegration.PSA_Default_User_Profile__c].Id;
            newUser.UserName += '.' + psaIntegration.PSA_Username_Suffix__c;
        }
    }
 
    /**************************************************************************************
    // Name         : getResourceRegionId
    // Description  : Look up the Region Id from the Region object based on the WD Region ID external id
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    private static Id getResourceRegionId(String workdayRegionId, PSA_Resource_Stage__c resourceStage, 
            Boolean newResource, Map<String, pse__Region__c> regionMap) {
        //System.debug('workdayRegionId:'+workdayRegionId);
        String logMessage = '';
        Id psaRegionId; 

        pse__Region__c region = regionMap.get(workdayRegionId);
        if (region == null) {
            logMessage = 'Missing the WD Region ID: ' + workdayRegionId;
        } else {
            psaRegionId = region.Id;
        }

        //Write an entry to the Integration Log
        if (logMessage != '') {
            String integrationType;
            if (newResource) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_RESOURCE; }
            else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_UPDATED_RESOURCE; }

            psaIntegrationUtils.writeLogEntry(resourceStage.Id, 'Resource', integrationType, 
                psaIntegrationUtils.LOG_TYPE_WARNING, logMessage, null, resourceStage.PSA_GW_Integration_Id__c, null);
        
            Throw new psaException('Missing the Workday Region ID value in the Region object: ' + workdayRegionId);
        }

        return psaRegionId;
    }
 
    /**************************************************************************************
    // Name         : getResourceWorkCalendarId
    // Description  : Look up the Work Calendar Id from the Work Calendar object based on the WD Calendar Name external id
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    private static Id getResourceWorkCalendarId(String workdayCalendarName, PSA_Resource_Stage__c resourceStage, 
            Boolean newResource, Map<String, pse__Work_Calendar__c> workCalendarMap) {
        String logMessage = '';
        Id psaWorkCalendarId;

        pse__Work_Calendar__c workCalendar = workCalendarMap.get(workdayCalendarName);
        if (workCalendar == null) {
            logMessage = 'Missing the WD Work Calendar Name: ' + workdayCalendarName;
        } else {
            psaWorkCalendarId = workCalendar.Id;
        }

        //Write an entry to the Integration Log
        if (logMessage != '') {
            String integrationType;
            if (newResource) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_RESOURCE; }
            else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_UPDATED_RESOURCE; }

            psaIntegrationUtils.writeLogEntry(resourceStage.Id, 'Resource', integrationType, 
                psaIntegrationUtils.LOG_TYPE_WARNING, logMessage, null, resourceStage.PSA_GW_Integration_Id__c, null);

            Throw new psaException('Missing the Workday Calendar Name value in the Work Calendar object: ' + workdayCalendarName);
        }

        return psaWorkCalendarId;
    }
 
    /**************************************************************************************
    // Name         : getResourceAccount
    // Description  : Look up the Pract Id from the Region object based on the WD Region ID external id
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    private static Id getResourceAccount(PSA_Resource_Stage__c resourceStage) {
        Id accountId;
        String logMessage = '';
        PSA_Integration__c psaIntegration = PSA_Integration__c.getValues('default');
        if (psaIntegration == null) {
            logMessage = 'Missing the "default" PSA Integration custom setting';
        } else {
            if (resourceStage.PSA_Worker_Type__c == 'Employee') {
                accountId = psaIntegration.PSA_Guidewire_Account_Id__c;
            }
        }

        //Write an entry to the Integration Log
        if (logMessage != '') {
            psaIntegrationUtils.writeLogEntry(resourceStage.Id, 'Resource', psaIntegrationUtils.INTERGRATION_TYPE_NEW_RESOURCE, 
                psaIntegrationUtils.LOG_TYPE_WARNING, logMessage, null, resourceStage.PSA_GW_Integration_Id__c, null);

            Throw new psaException('Missing the "default" PSA Integration custom setting');
        }

        return accountId;
    }
 
    /**************************************************************************************
    // Name         : getPractice
    // Description  : If this is a new resource, get the Resource's Practice
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 2015-07-08  Klassen  Don't require Practice if the Dept is a non PS Dept
    ***************************************************************************************/
    private static Id getPractice(PSA_Resource_Stage__c resourceStage, Boolean newResource, 
            Map<String, PSA_Resource_Practice__c> resourcePracticeMap, Boolean isPSDepartment) {
        Id practiceId;
        String logMessage = '';

        String mapKey = resourceStage.PSA_Department__c + ':' + resourceStage.PSA_Entity_Id__c;
        PSA_Resource_Practice__c resourcePractice = resourcePracticeMap.get(mapKey);

        if (resourcePractice == null) {
            logMessage = 'Missing Practice from PSA Resource Practice mapping table for Entity: ' + 
                resourceStage.PSA_Entity_Id__c + ' and Department: ' + resourceStage.PSA_Department__c;
        } else {
            practiceId = resourcePractice.PSA_Practice__c;
        }

        //Write an entry to the Integration Log
        if (logMessage != '') {
            String integrationType;
            if (newResource) { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_NEW_RESOURCE; }
            else { integrationType = psaIntegrationUtils.INTERGRATION_TYPE_UPDATED_RESOURCE; }

            psaIntegrationUtils.writeLogEntry(resourceStage.Id, 'Resource', integrationType, 
                    psaIntegrationUtils.LOG_TYPE_WARNING, logMessage, null, resourceStage.PSA_GW_Integration_Id__c, null);

            //Only throw an exeception if the resource is not a Transfer Out, ie. the Department is a PS Dept
            if (isPSDepartment == true) {
                Throw new psaException(logMessage);
            }
        }

        return practiceId;
    }   

    /**************************************************************************************
    // Name         : setGroup
    // Description  : If this is a new resource, get the Resource's Group
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    private static Id getGroup(PSA_Resource_Stage__c resourceStage) {
        Id groupId;
        groupId = [Select Id From pse__Grp__c Where Name = 'Corporate' LIMIT 1].Id;
        return groupId;
    }   

    /**************************************************************************************
    // Name         : updateSalesforceUser
    // Description  : update the SF User on the Resource if missing
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    public static void updateSalesforceUser(List<Contact> contactsToUpdate) {
        Set<String> workerIds = new Set<String>();
        Map<String, User> userMap = new Map<String, User>();
        System.debug('updateSalesforceUser: ' + contactsToUpdate);

        for (Contact cont : contactsToUpdate) {
            workerIds.add(cont.PSA_Worker_Id__c);
        }

        List<User> userList = 
            [Select Id, PSA_Worker_Id__c
                From User
                Where PSA_Worker_Id__c In :workerIds
            ];
        if (userList != null && userList.size() > 0) {
            for (User usr : userList) {
                userMap.put(usr.PSA_Worker_Id__c, usr);
            }
        }

        User foundUser;
        for (Contact cont : contactsToUpdate) {
            foundUser = userMap.get(cont.PSA_Worker_Id__c);
            if (foundUser != null) {
                cont.pse__Salesforce_User__c = foundUser.Id;
            }
        }

        update contactsToUpdate;
    }

    /**************************************************************************************
    // Name         : getIsPSDepartment
    // Description  : Check if the Department is a PS Dept.  If not, ignore validations for
    //                  Practice, non-PS Dept (?), and Manager (?)
    // Author       : CLD Partners
    // Revisions    : 2015-07-07  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    public static Boolean getIsPSDepartment(PSA_Resource_Stage__c resourceStage, 
            Map<String, PSA_Department__c> departmentMap) {
        Boolean isPSDepartment = false;
        if (resourceStage.PSA_Department__c != null) {
            PSA_Department__c dept = departmentMap.get(resourceStage.PSA_Department__c);
            if (dept != null && dept.PSA_PS_Department__c == true) {
                isPSDepartment = true;
            }
        }

        return isPSDepartment;
    }

    /**************************************************************************************
    // Name         : scheduleUpdateUser
    // Description  : Create a scheduled job to update the SF User (will run once)
    // Author       : CLD Partners
    // Revisions    : 2015-04-08  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    public static void scheduleUpdateUser() {
        //psaResourceStageBatch b = new psaResourceStageBatch(true);
        //String cronID = System.scheduleBatch(b, 'Resource Stage Batch', 1);

        //Build a Cron to schedule a job in the next 2 minutes
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute() + 1); 
        String ss = String.valueOf(Datetime.now().second());

        //parse to cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';

        psaResourceStageSchedulable s = new psaResourceStageSchedulable(); 
        System.schedule('PSA SF User Update - 1 Time: ' + String.valueOf(Datetime.now()), nextFireTime, s);
    }

}