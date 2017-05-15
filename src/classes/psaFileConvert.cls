/**************************************************************************************
// Name          : psaFileConvert
// Date          : November 19, 2015 
// Description   : Utility class to convert non image formatted files into an image format
// Author        : CLD Partners
// Revisions     : 2015-11-19 Klassen initial version
//               : 2016-03-12 Klassen Optimized scheduling timing
//               : 2016-03-25 Klassen Fixed bug that was not creating the combined receipts
//                      doc if there were no non-image files to be converted
// Basic Flow:
// 1. Get a list of expenses that have attachments 
// 2. Get a list of the expense attachments that are not in an image format
// 3. Add attachment details to a custom object "PSA File Convert" which will store the conversion status
// 4. Loop through PSA File Convert and initiate the conversion process for each attachment -- based on the job id
// 5. Run separate process to check the status of each job (initiated by scheduled job b/c of callout limitations)
// 6. If the status is "successful", get the converted file and insert as an Attachment
***************************************************************************************/
global without sharing class psaFileConvert {
    public psaFileConvert() {}

    //Variables to store zamzar-related settings
    public static String baseURL = psaFileConvertZamzar.getBaseURL();
    public static String convertedFileDescription = 'Zamzar-';
    public static String targetFileIdentifier = '-conv-'; //used as part of attachment name

    //Variables to store PSA Combine Receipts custom setting values
    public static PSA_Combine_Receipts__c customSettingCombineReceipts;
    public static String notifyEmailList;
    public static Decimal notificationThreshold;
    public static String zamzarAPIKey;
    public static String targetFormat;
    public static Decimal maxFileConvertAttempts;

    /**************************************************************************************
    // Name         : beginExpenseReportConversion
    // Description  : This method allows the file conversion process to begin from a Detail 
    //                  page button.  The process will abort if either there are no expense
    //                  attachments or if the combining process is in progres.
    // Author       : CLD Partners
    // Revisions    : 2016-03-06  Klassen  Initial Implementation
    //              : 2016-05-02  Klassen  Updated to prevent the process from starting if 
    //                      there are no expense receipts (attachments) or if the process
    //                      is alredy in progress
    ***************************************************************************************/
    Webservice static string beginExpenseReportConversion(String requestType, String sourceObjectId) {
        string message = '';
        try {
            List<pse__Expense__c> expenses;
            if (requestType == 'ExpenseReport') {
                expenses = 
                    [Select Id, Name, pse__Expense_Report__r.PSA_Doc_Gen_Start__c, 
                            pse__Expense_Report__r.PSA_Doc_Gen_End__c 
                        From pse__Expense__c
                        Where pse__Expense_Report__c =: sourceObjectId
                        And PSA_Receipt_Attached__c = true
                        Order By Name
                    ];
            }
            if (expenses != null && expenses.size() > 0) {
                Boolean processInProgress = false;
                Set<Id> expenseIds = new Set<Id>();
                for (pse__Expense__c expense : expenses) {
                    if (expense.pse__Expense_Report__r.PSA_Doc_Gen_Start__c != null &&
                            expense.pse__Expense_Report__r.PSA_Doc_Gen_End__c == null) {
                        processInProgress = true;
                        System.debug('Breaking out of expense loop');
                        break;
                    }
                    expenseIds.add(expense.Id);
                }

                if (processInProgress == true) {
                    message = 'The Receipt Combination work is already in progress.';
                } else {
                    initiateConversionBatch(expenseIds, sourceObjectId, requestType);

                    message = 'SUCCESS';
                }
            } else {
                message = 'No expenses were found.';
            }
        } catch(System.CalloutException e) {
            message = e.getMessage();
        }
        return message;
    }

    /**************************************************************************************
    // Name         : initiateConversionBatch
    // Description  : Start the conversion process with a list of expenses -- run the process
    //                  in batches to avoid heap size limit errors
    // Author       : CLD Partners
    // Revisions    : 2016-03-16  Klassen  Initial Implementation
    //              : 2016-03-25  Klassen  Fixed bug that was not creating the combined receipts
    //                      doc if there were no non-image files to be converted
    //              : 2016-05-02  Klassen  Added code to set the status of the process
    ***************************************************************************************/
    public static void initiateConversionBatch(Set<Id> expenseIdsWithAttachments, 
            String sourceObjectId, String sourceObjectType) {

        //Set the Combine Receipt Progress value
        psaCombineExpenseReceipts.updateCombineReceiptProgress('Started', sourceObjectId, 
            sourceObjectType, true, false);

        List<Attachment> attachments = 
            [select Id
                from Attachment
                where ParentId =: expenseIdsWithAttachments
                and (NOT ContentType Like 'image/%') 
                and (Not Name Like '%.msg') 
				and (Not Name Like '%.txt')
				and (Not Name Like '%.csv')				 
            ];
        System.debug('Attachments: ' + attachments);
        if (attachments != null && attachments.size() > 0) {
            Set<Id> attachmentIds = new Set<Id>();
            for (Attachment a : attachments) {
                attachmentIds.add(a.Id);
            }
            System.debug('Non-image Attachment Ids: ' + attachmentIds);

            //Initialize the batchNumber variable with -1
            Decimal batchNumber = getNextBatchNumber(expenseIdsWithAttachments);

            //** Call a batch job to upload the non-image files to Zamzar, one at a time (batch size=1).  This is done
            // to help prevent a heap size limit error
            Integer BATCH_SIZE = 1; 
            Boolean sendEmail = false;           
            psaFileConvertBatch fileConvertBatch = new psaFileConvertBatch(attachmentIds, 
                    batchNumber, sendEmail, sourceObjectType, sourceObjectId);
            Id batchId = database.executeBatch(fileConvertBatch, BATCH_SIZE);    
            System.debug('**** psaFileConvert: Batch executed batchId: ' +batchId);

            //Set the Combine Receipt Progress value
            psaCombineExpenseReceipts.updateCombineReceiptProgress('Converting Files', sourceObjectId, 
                sourceObjectType, false, false);
        } else {
            //No non-image attachments were found, so skip the file conversion logic and go straight
            // to scheduling the combine expense receipts job
            psaCombineExpenseReceipts.scheduleCombineExpenseReceipts(null, sourceObjectId, sourceObjectType);
        }
    }

    /**************************************************************************************
    // Name         : initiateConversion
    // Description  : Start the conversion process with a list of expenses (may not need to
    //                  convert any files if all are in an image format)
    // Author       : CLD Partners
    // Revisions    : 2015-11-15  Klassen  Initial Implementation
    //              : 2016-03-17  Klassen  Moved some logic out into a batch class (psaFileConvertBatch)
    ***************************************************************************************/
    public static void initiateConversion(Set<Id> attachmentIds, String sourceObjectId, 
            String sourceObjectType, Decimal batchNumber) {
        List<PSA_File_Convert__c> fileConvertRecsToInsert = new List<PSA_File_Convert__c>();

        List<Attachment> attachments = 
            [select Body, BodyLength, ContentType, Description, Id, IsPrivate, Name, ParentId 
                from Attachment
                where Id =: attachmentIds
            ];
        Set<Id> expenseIds = new Set<Id>();
        for (Attachment attach : attachments) {
            expenseIds.add(attach.ParentId);
        }
        List<PSA_File_Convert__c> filesToConvert = 
            [Select Id, Name, PSA_Expense__c, PSA_Source_File_Name__c, PSA_Conversion_Status__c, 
                    PSA_Batch_Number__c
                From PSA_File_Convert__c
                Where PSA_Expense__c =: expenseIds
            ];
        System.debug('Attachments: ' + attachments);
        System.debug('Matching Files To Convert: ' + filesToConvert);
        if (attachments != null && attachments.size() > 0) {

            //Load the combine receipts custom settings values (if not already loaded) -- set targetFormat
            loadCustomSettingsVariables();
            String fileHasAlreadyBeenConverted;
            for (Attachment attach : attachments) {
                //Check if the attachment has already been converted.  If so, skip it
                fileHasAlreadyBeenConverted = checkIfFileHasBeenConverted(filesToConvert, attach.Name, 
                    attach.ParentId);
                if (fileHasAlreadyBeenConverted == 'no') {
                    //call Zamzar conversion api
                    String responseString; 
                    responseString = uploadFileToConvert(attach.Body, attach.Name, baseURL + 'jobs?target_format=' + targetFormat);
                    
                    PSA_File_Convert__c fileToConvert = new PSA_File_Convert__c();
                    fileToConvert.PSA_Batch_Number__c = batchNumber;
                    fileToConvert.PSA_Expense__c = attach.ParentId;
                    fileToConvert.PSA_Attachment_Parent_Id__c = attach.ParentId;
                    fileToConvert.PSA_Target_Format__c = targetFormat;
                    fileToConvert.PSA_Source_Attachment_Id__c = attach.Id;
                    fileToConvert.PSA_Source_File_Name__c = attach.Name;
                    fileToConvert.PSA_File_Convert_HTTP_Response__c = responseString;
                    fileToConvert.PSA_Conversion_Status__c = parseJSONForKeyValue(responseString, 'status', null);
                    fileToConvert.PSA_Conversion_Job_Id__c = parseJSONForKeyValue(responseString, 'id', null);
                    fileToConvert.PSA_Source_File_Job_Id__c = parseJSONForKeyValue(responseString, 'source_file', 'id');
                    fileToConvert.PSA_Batch_Type__c = sourceObjectType;
                    fileConvertRecsToInsert.add(fileToConvert);
                } else if (fileHasAlreadyBeenConverted.contains('in progress:')) {
                    //set the batch number
                    batchNumber = Integer.valueOf(fileHasAlreadyBeenConverted.replace('in progress:', ''));
                }
            }
        }
    
        if (fileConvertRecsToInsert.size() > 0) {
            insert fileConvertRecsToInsert;
        }
    }

    /**************************************************************************************
    // Name         : checkIfFileHasBeenConverted
    // Description  : Check if a file has already been converted based on whether the 
    //                  combination of attachment (file) name plus parent id is in the PSA 
    //                  File Convert object
    // Author       : CLD Partners
    // Revisions    : 2015-12-01  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    public static String checkIfFileHasBeenConverted(List<PSA_File_Convert__c> filesConverted, 
            String fileName, Id expenseId) {
        String responseValue = 'no';
        if (filesConverted != null || filesConverted.size() > 0) {
            //Check if the file has already been added to the PSA File Convert object as a record
            for (PSA_File_Convert__c fileConverted : filesConverted) {
                if (fileConverted.PSA_Source_File_Name__c == fileName && fileConverted.PSA_Expense__c == expenseId) {
                    if (fileConverted.PSA_Conversion_Status__c != 'successful' && fileConverted.PSA_Conversion_Status__c != 'ignore') {
                        responseValue = 'in progress:' + fileConverted.PSA_Batch_Number__c;
                    } else {
                        responseValue = 'yes';
                    }
                    System.debug('Found matching Converted File: ' + fileConverted);
                    break;
                }
            }
        }

        return responseValue;
    }

    /**************************************************************************************
    // Name         : parseJSONForKeyValue
    // Description  : Search for a value within a JSON-formatted string (up to 2 levels deep)
    //                  
    // Author       : CLD Partners
    // Revisions    : 2015-11-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    public static String parseJSONForKeyValue(String jsonString, String primaryKey, 
            String secondaryKey) {
        String keyName = primaryKey;
        String keyValue;

        JSONParser parser = JSON.createParser(jsonString);
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                String fieldName = parser.getText();
                parser.nextToken();
                if(fieldName == keyName) {
                    if (secondaryKey != null && secondaryKey != '' && keyName == primaryKey) {
                        keyName = secondaryKey;
                    } else {
                        keyValue = parser.getText();
                        break;
                    }
                }
            }
        }

        return keyValue;
    }

    /**************************************************************************************
    // Name         : checkJobs
    // Description  : Check on any file conversion jobs to see if they have completed.  If
    //                  any have been successfully completed, upload the converted file(s) 
    //                  as attachments to the original expense
    // Author       : CLD Partners
    // Revisions    : 2015-11-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    public static void checkJobs(Set<Id> fileConvertIds) {
        //Get list of PSA File Convert records based on a batch number
        List<PSA_File_Convert__c> filesToConvert = 
            [Select Id, Name, PSA_Conversion_Job_Id__c, PSA_Target_File_Job_Id__c, 
                    PSA_Source_File_Name__c, PSA_File_Convert_Status_HTTP_Response__c, 
                    PSA_Attachment_Parent_Id__c, PSA_Target_Format__c 
                From PSA_File_Convert__c
                Where Id = :fileConvertIds 
                And PSA_Conversion_Job_Id__c != null 
                And PSA_Conversion_Status__c != 'successful'
                And PSA_Conversion_Status__c != 'ignore'
            ];
        if (filesToConvert != null && filesToConvert.size() > 0) {
            //Added 3/15/16 by cklassen to prevent heap size error
            Integer maxSize = 10000000;
            Integer runningSize = 0;
            Integer currentSize;
            Boolean endFileProcessing = false;

            Set<Id> expensesToUpdateById = new Set<Id>();
            List<Attachment> newAttachments = new List<Attachment>();
            Attachment convertedFileAttachment;
            String jobStatus;
            for (PSA_File_Convert__c fileToConvert : filesToConvert) {
                //Get the file conversion job status
                HTTPResponse res = processGETRequest('jobs/' + fileToConvert.PSA_Conversion_Job_Id__c, false);
                String httpResponseValue = res.getBody();
                jobStatus = parseJSONForKeyValue(httpResponseValue, 'status', null);
                System.debug('Conversion Job Status: ' + jobStatus);
                if (jobStatus == 'successful') {
                    //Get a list of file ids from the response value since a single source file may have
                    // more than one resulting converted file -- a multi-page PDF to PNG conversion
                    List<psaFileConvertZamzar.ZamzarTargetFile> targetFiles = psaFileConvertZamzar.getTargetFileNames(httpResponseValue);
                    if (targetFiles.size() > 0) {
                        fileToConvert.PSA_Target_File_Count__c = targetFiles.size();
                        Integer counter = 1;
                        String targetFileName;
                        for (psaFileConvertZamzar.ZamzarTargetFile targetFile : targetFiles) {
                            runningSize += targetFile.size;
                            if (runningSize > maxSize) {
                                System.debug('Max size reached, so this will be the last set of files processed');
                                endFileProcessing = true;
                            } 
                            //add to list of files to retrieve
                            System.debug('Target File Id: ' + targetFile.id);
                            targetFileName = setTargetFileName(fileToConvert.PSA_Source_File_Name__c, 
                                    fileToConvert.PSA_Target_Format__c, targetFileIdentifier, targetFiles.size(), counter); 
                            System.debug('Target (Attachment) File Name: ' + targetFileName);

                            convertedFileAttachment = createAttachmentFromConvertedFile(String.valueOf(targetFile.id), targetFileName, 
                                fileToConvert.PSA_Attachment_Parent_Id__c, fileToConvert.PSA_Target_Format__c, targetFile.name);
                            if (convertedFileAttachment != null) {
                                newAttachments.add(convertedFileAttachment);
                            }
                            counter++;
                        }
                    }
                }
                fileToConvert.PSA_Conversion_Status__c = jobStatus;
                fileToConvert.PSA_File_Convert_Status_HTTP_Response__c = httpResponseValue;

                if (endFileProcessing == true) {
                    System.debug('Breaking out of files to convert loop');
                    break;
                }
            }
            System.debug('New Attachments Size: ' + newAttachments.size());
            if (newAttachments.size() > 0) {
                insert newAttachments;
            }

            update filesToConvert;
        }
    }

    /**************************************************************************************
    // Name         : createAttachmentFromConvertedFile
    // Description  : Save a converted file as an attachment
    //                  
    // Author       : CLD Partners
    // Revisions    : 2015-11-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    public static Attachment createAttachmentFromConvertedFile(String jobId, String fileName, 
            Id parentId, String imageType, String convertedFileName) {
        HTTPResponse res = processGETRequest('files/' + jobId + '/content', true);

        if (res.getStatusCode() == 200) {
            //create a new attachment 
            String fileDescription = convertedFileDescription + ' (Job Id=' + jobId + ')';

            Attachment convertedFile = new Attachment(Name=fileName);
            convertedFile.Body = res.getBodyAsBlob();
            convertedFile.Description = fileDescription;
            convertedFile.ParentId = parentId;
            convertedFile.ContentType = 'image/' + imageType;
            return convertedFile;
        } else {
            return null;
        }
    }

    /**************************************************************************************
    // Name         : uploadFileToConvert
    // Description  : Upload an Attachment (passed in as a Blob) to the File Conversion
    //                  service
    // Author       : CLD Partners
    // Revisions    : 2015-11-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    public static String uploadFileToConvert(Blob file_body, String file_name, String reqEndPoint) {
        // Credits: 
        // Repost of code  with fix for file corruption issue
        // Orignal code postings and explanations
        // http://enreeco.blogspot.in/2013/01/salesforce-apex-post-mutipartform-data.html
        // http://salesforce.stackexchange.com/questions/24108/post-multipart-without-base64-encoding-the-body
        // Additional changes commented GW: that fix issue with occasional corruption of files
        String boundary = '----------------------------741e90d31eff';
        String header = '--'+boundary+'\nContent-Disposition: form-data; name="source_file"; filename="'+file_name+'";\nContent-Type: application/octet-stream';

        // GW: Do not prepend footer with \r\n, you'll see why in a moment
        // String footer = '\r\n--'+boundary+'--'; 
        String footer = '--'+boundary+'--';             
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        while(headerEncoded.endsWith('=')) {
            header+=' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        }
        String bodyEncoded = EncodingUtil.base64Encode(file_body);
        // GW: Do not encode footer yet
        // String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));

        Blob bodyBlob = null;
        String last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());

        // Section to get rid of padding without corrupting data
        if(last4Bytes.endsWith('==')) {
            // The '==' sequence indicates that the last group contained only one 8 bit byte
            // 8 digit binary representation of CR is 00001101
            // 8 digit binary representation of LF is 00001010
            // Stitch them together and then from the right split them into 6 bit chunks
            // 0000110100001010 becomes 0000 110100 001010
            // Note the first 4 bits 0000 are identical to the padding used to encode the
            // second original 6 bit chunk, this is handy it means we can hard code the response in
            // The decimal values of 110100 001010 are 52 10
            // The base64 mapping values of 52 10 are 0 K
            // See http://en.wikipedia.org/wiki/Base64 for base64 mapping table
            // Therefore, we replace == with 0K
            // Note: if using \n\n instead of \r\n replace == with 'oK'
            last4Bytes = last4Bytes.substring(0,2) + '0K';
            bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
            // We have appended the \r\n to the Blob, so leave footer as it is.
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);
        } else if(last4Bytes.endsWith('=')) {
            // '=' indicates that encoded data already contained two out of 3x 8 bit bytes
            // We replace final 8 bit byte with a CR e.g. \r
            // 8 digit binary representation of CR is 00001101
            // Ignore the first 2 bits of 00 001101 they have already been used up as padding
            // for the existing data.
            // The Decimal value of 001101 is 13
            // The base64 value of 13 is N
            // Therefore, we replace = with N
            // Note: if using \n instead of \r replace = with 'K'
            last4Bytes = last4Bytes.substring(0,3) + 'N';
            bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
            // We have appended the CR e.g. \r, still need to prepend the line feed to the footer
            footer = '\n' + footer;
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);              
        } else {
            // Prepend the CR LF to the footer
            footer = '\r\n' + footer;
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);  
        }

        //Now make the HTTP request and return the body of the HTTP Response
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type','multipart/form-data; boundary='+boundary);
        //System.debug('Header: Content-Type: multipart/form-data; boundary='+boundary);
        //Load the combine receipts custom settings values (if not already loaded)
        loadCustomSettingsVariables();
        Blob headerValue = Blob.valueOf(zamzarAPIKey + ':');
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(headerValue));
        req.setMethod('POST');
        req.setEndpoint(reqEndPoint);
        req.setBodyAsBlob(bodyBlob);
        req.setTimeout(120000);

        Http http = new Http();
        HTTPResponse res = http.send(req);
        //System.debug('uploadFileToConvert Response: ' + res.getBody());

        return res.getBody();
    }

    /**************************************************************************************
    // Name         : processGETRequest
    // Description  : Make a GET request and return the HTTP Response results. Includes 
    //                  logic to handle a redirect
    // Author       : CLD Partners
    // Revisions    : 2015-11-15  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    public static HTTPResponse processGETRequest(String endpointSuffix, Boolean noDebugBody) {
        //Credits:
        //Redirect code taken from 
        // http://salesforce.stackexchange.com/questions/11126/how-do-i-handle-a-302-redirect-response-to-my-http-callout

        HTTPResponse res = psaFileConvertZamzar.processGETRequest(endpointSuffix, noDebugBody);

        //check for redirect
        boolean redirect = false;
        if(res.getStatusCode() >=300 && res.getStatusCode() <= 307 && res.getStatusCode() != 306) {
            HttpRequest req;
            Http http = new Http();

            do {
                redirect = false; // reset the value each time
                String loc = res.getHeader('Location'); // get location of the redirect
                if(loc == null) {
                    redirect = false;
                    continue;
                }
                req = new HttpRequest();
                req.setEndpoint(loc);
                req.setMethod('GET');
                res = http.send(req);
                if(res.getStatusCode() != 500) { // 500 = fail
                    if(res.getStatusCode() >=300 && res.getStatusCode() <= 307 && res.getStatusCode() != 306) {
                        redirect= true;
                    }
                    // I do special handling here with cookies
                    // if you need to bring a session cookie over to the
                    // redirected page, this is the place to grab that info
                }
            } while (redirect && Limits.getCallouts() != Limits.getLimitCallouts());
        }

        if (!noDebugBody) {
            System.debug('THE RESPONSE IS: '+res.getBody());
        }
        System.debug('toString: '+res.toString());
        //System.debug('getBodyAsBlob: '+res.getBodyAsBlob());
        System.debug('getHeaderKeys: '+res.getHeaderKeys());
        System.debug('getHeader-Location: '+res.getHeader('Location'));

        return res;
    }

    /**************************************************************************************
    // Name         : getNextBatchNumber
    // Description  : Find the batch number for a set of expenses.  If none is found get the 
    //                  maximum batch number value and add 1 to it.
    // Author       : CLD Partners
    // Revisions    : 2015-11-22  Klassen  Initial version
    //              : 2016-03-17  Klassen  Add additional criteria to limit the amount of records
    ***************************************************************************************/
    public static Decimal getNextBatchNumber(Set<Id> expenseIds) {
        Decimal nextBatchNumber = 0;
        Date oldestDate = Date.Today().addDays(-90);
        List<PSA_File_Convert__c> fileConvertList = 
            [select PSA_Batch_Number__c
                from PSA_File_Convert__c
                where createddate > :oldestDate
                and PSA_Expense__c = :expenseIds
                order by PSA_Batch_Number__c desc
                limit 1
            ];
        if (fileConvertList != null && fileConvertList.size() > 0) {            
            nextBatchNumber = fileConvertList[0].PSA_Batch_Number__c;
        } else {
            fileConvertList = 
                [select PSA_Batch_Number__c
                    from PSA_File_Convert__c
                    where createddate > :oldestDate
                    order by PSA_Batch_Number__c desc
                    limit 1
                ];
            if (fileConvertList != null && fileConvertList.size() > 0) {            
                nextBatchNumber = fileConvertList[0].PSA_Batch_Number__c + 1;
            }
        }
        return nextBatchNumber;
    }

    /**************************************************************************************
    // Name         : setTargetFileName
    // Description  : Define a target file name based on the source file name, a string
    //                  identifier, and the number files in a series are being converted
    // Author       : CLD Partners
    // Revisions    : 2015-11-22  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    public static String setTargetFileName(String sourceFileName, String targetFileExtension, 
             String fileNameSuffix, Integer totalFileCount, Integer fileCounter) {
        String targetFileName;
        targetFileName = sourceFileName + targetFileIdentifier + fileCounter + 'of' + 
            totalFileCount + '.' + targetFileExtension;
        return targetFileName;
    }

    /**************************************************************************************
    // Name         : checkJobsByBatch
    // Description  : Check on the status of the converted files request for a specific 
    //                  batch number.  If there were no files to convert or if all of the 
    //                  files have been successfully converted, schedule the job that will
    //                  create the combined receipt pdf file.  If some of the files for the 
    //                  batch are not yet converted, re-schedule the job runs this method again
    // Author       : CLD Partners
    // Revisions    : 2016-03-17  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    public static void checkJobsByBatch(Decimal batchNumber, String attachmentParentId, 
            String sourceObjectType, Integer attemptCount) {
        System.debug('checkJobsByBatch Batch Number: ' + batchNumber);

        //** Call a batch job to upload the non-image files to Zamzar, one at a time (batch size=1).  This is done
        // to help prevent a heap size limit error
        Integer BATCH_SIZE = 1; 
        Boolean sendEmail = false;           
        psaFileConvertCheckJobsBatch fileConvertCheckJobs = new psaFileConvertCheckJobsBatch( 
                batchNumber, attachmentParentId, sourceObjectType, attemptCount, sendEmail);
        Id batchId = database.executeBatch(fileConvertCheckJobs, BATCH_SIZE);    
        System.debug('**** psaFileConvert.checkJobsByBatch executed batchId: ' +batchId); 
    }

    /**************************************************************************************
    // Name         : checkJobStatusByBatch
    // Description  : Check on the status of the converted files request for a specific 
    //                  batch number.  If there were no files to convert or if all of the 
    //                  files have been successfully converted, schedule the job that will
    //                  create the combined receipt pdf file.  If some of the files for the 
    //                  batch are not yet converted, re-schedule the job runs this method again
    // Author       : CLD Partners
    // Revisions    : 2015-12-01  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    public static void checkJobStatusByBatch(Decimal batchNumber, String attachmentParentId, 
            String sourceObjectType, Integer attemptCount) {
        System.debug('checkJobStatusByBatch Batch Number: ' + batchNumber);

        //Check the status of all PSA File Convert records for the specified Batch Number.
        // If not all are successful, schedule the job to run again.  If all are successful, 
        // build the combined file and attach it to the expense report
        List<PSA_File_Convert__c> filesToConvert = 
            [Select Id, Name
                From PSA_File_Convert__c
                Where PSA_Batch_Number__c = :batchNumber
                And PSA_Conversion_Status__c != 'successful'
                And PSA_Conversion_Status__c != 'ignore'
            ];
        System.debug('filesToConvert: ' + filesToConvert);
        if (filesToConvert == null || filesToConvert.size() == 0) {
            psaCombineExpenseReceipts.scheduleCombineExpenseReceipts(null, attachmentParentId, sourceObjectType);
        } else {
            attemptCount += 1;
            scheduleJobByBatchNumber(batchNumber, attachmentParentId, sourceObjectType, attemptCount);
        }
    }

    /**************************************************************************************
    // Name         : scheduleJobByBatchNumber
    // Description  : Schedule a job to check on the status of the converted files request
    //                  for a specific batch number.
    // Author       : CLD Partners
    // Revisions    : 2015-12-01  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    public static void scheduleJobByBatchNumber(Decimal batchNumber, String attachmentParentId, 
            String sourceObjectType, Integer attemptCount) {
        //Schedule a job to run that will either create a new scheduled job or attach a 
        // combined receipts file to the parent (expense report or billing event)

        //Define the time to launch the scheduled job
        Integer xSeconds = 60;
        if (attemptCount == 1) {
            xSeconds = 5;
        }
        Datetime sysTime = System.now().addSeconds( xSeconds );
        String cronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + 
            sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();

        //Schedule the job
        psaCombineExpenseReceiptsDocSchedulable s = 
                new psaCombineExpenseReceiptsDocSchedulable(batchNumber, attachmentParentId, sourceObjectType, attemptCount); 

        //Load the custom settings variables (if they haven't already been loaded into memory)
        loadCustomSettingsVariables();

        //Check if we've reached the maximum number of attempts to convert files.  If max attempts has been reached, 
        // send an email to a PSA Admin (if an email notification list has been set up in the custom setting)
        if (attemptCount <= maxFileConvertAttempts) {
            System.schedule('PSA Combine Receipts Doc (batch ' + batchNumber +'): ' + String.valueOf(Datetime.now()), cronExpression, s);
        } else {
            //send an email notification or throw an error?
            System.debug('Max retries reached -- aborting job re-scheduling');
            String subjectText = 'Max File Convert Job Scheduling Attempts for Batch #: ' + batchNumber;
            String bodyText = subjectText + ' (# of attempts: ' + attemptCount + ', User Name: ' + UserInfo.getUserName() + 
                ', Object Type: ' + sourceObjectType + ', Object Id: ' + attachmentParentId + ')';
            sendEmailNotification(subjectText, bodyText);
            
        }
        System.debug('current date time: ' + String.valueOf(Datetime.now()));
        System.debug('current date: ' + String.valueOf(Date.today()));
    }

    /**************************************************************************************
    // Name         : loadCustomSettingsVariables
    // Description  : If the custom settings variables haven't been loaded, do it now
    //
    // Author       : CLD Partners
    // Revisions    : 2015-12-07  Klassen  Initial version
    //              : 
    ***************************************************************************************/
    public static void loadCustomSettingsVariables() {
        //Only set the custom settings variables if the "default" custom setting hasn't
        // been "loaded" yet
        if (customSettingCombineReceipts == null) {
            //Set the default values
            notifyEmailList = '';
            notificationThreshold = 0;
            zamzarAPIKey = '';
            targetFormat = '';
            maxFileConvertAttempts = 5;

            PSA_Combine_Receipts__c psaCombineReceipts = PSA_Combine_Receipts__c.getValues('default');
            if (psaCombineReceipts != null) {
                if (psaCombineReceipts.PSA_Max_Convert_Attempts__c != null) {
                    maxFileConvertAttempts = psaCombineReceipts.PSA_Max_Convert_Attempts__c;
                }
                if (psaCombineReceipts.PSA_Notification_Threshold__c != null) {
                    notificationThreshold = psaCombineReceipts.PSA_Notification_Threshold__c;
                }
                if (psaCombineReceipts.PSA_Email_Notify_List__c != null) {
                    notifyEmailList = psaCombineReceipts.PSA_Email_Notify_List__c;
                }
                if (psaCombineReceipts.PSA_Zamzar_API_Key__c != null) {
                    zamzarAPIKey = psaCombineReceipts.PSA_Zamzar_API_Key__c;
                }
                if (psaCombineReceipts.PSA_Target_Format__c != null) {
                    targetFormat = psaCombineReceipts.PSA_Target_Format__c;
                }
            }       
        }
    }

    /**************************************************************************************
    // Name         : sendEmailNotification
    // Description  : This method sends a notification via email 
    // Author       : CLD Partners
    // Revisions    : 2016-01-11  Klassen  Initial Implementation
    //              : 
    ***************************************************************************************/
    public static void sendEmailNotification(String subjectText, String bodyText) {
        loadCustomSettingsVariables();
        if (notifyEmailList != '') {
            // Send a notification email 
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            String[] toAddresses = notifyEmailList.split(',');       
            mail.setToAddresses(toAddresses);
            mail.setSubject(subjectText);
            mail.setPlainTextBody(bodyText);

            if (!Test.isRunningTest()) {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }
}