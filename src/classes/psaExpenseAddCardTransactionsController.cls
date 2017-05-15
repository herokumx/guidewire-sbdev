/*********************************************************************************************** x
Name            : psaExpenseddCardTransactionsController
Author          : CLD
Created Date    : Oct 2015
Revision History: 03/08/2016 - Hari included to fetch  draft Expense Reports of the User.

Usage           : Controller for the psaExpenseAddCardTransactions page.
                :
***********************************************************************************************/
global class psaExpenseAddCardTransactionsController
{
    // -- Container for filter input start date holder (to allow for datepicker popup)
    public pse__Expense_Report__c dtHolderFrom {get; set;}

    // -- Container for filter input end date is under psa-posting (to allow for datepicker popup)
    public pse__Expense_Report__c dtHolderTo {get; set;}

    // Collection of card transaction wrappers
    public PSACardTransactionWrapper[] cardTransactionWrappers {get; set;}

    // Indicated we have card transaction wrappers to display
    public Boolean hasCardTransactions {get; set;}

    // - expense report displayed
    public pse__Expense_Report__c userExpenseReport {get; set;}
//    public Boolean userExpenseReportBillable {get; private set;}

    // indicates the expense report has been loaded for the page
    public Boolean expenseReportLoaded {get; set;}

    // Contains the summation totals displayed in the UI (using a custom object to display totals with Currency)
    //public PSA_Card_Transaction__c sumTransactionAmount {get; set;}

    // passed from ui - starting date range for card transactions
    public String filterStartDate {get; set;}

    // passed from ui - ending date range for card transactions
    public String filterEndDate {get; set;}

    public boolean hasPageError {get; set;}
    public String pageErrorMessage {get; set;}
    public boolean hasPageSuccess {get; set;}
    public String pageSuccessMessage {get; set;}

    public pse__Expense_Report__c[] recentlySavedExpenseReports {get; set;}
    public boolean hasRecentlySavedExpenses {get {
        return recentlySavedExpenseReports != null && recentlySavedExpenseReports.size() > 0;
        } set;}

    // returns the jsonTransIdsToClear
    public String savedTransIds {get; set;}


    // properties for itemized transaction logic
    public PSAItemizedTransactionWrapper itemizedTransWrapper {get; set;}
    public String transactionIdToItemize {get; set;} // passed from ui, this is the card transaction id to itemize.....
    public Boolean hasItemizedCardTransaction {get {return this.hasItemizedCardTransaction != null ? this.hasItemizedCardTransaction : false;} set;}

    // when an itemized transaction is saved, this will be set to true, to indicate that
    // the row should be removed from the card transactions listed on the page
    public Boolean isItemizedTransactionSaved {get {return this.isItemizedTransactionSaved != null ? this.isItemizedTransactionSaved : false;} set;}
    public String transactionIdSaved {get; set;} // passed to ui, to indicate that the transaction has been processed and should be removed from the ui list


    // ---- properties for advanced filter (expense card transactions); from non add to page

    // true when adding items from expense report
    public Boolean isAddFromExpenseReport {get; set;}

    // convenient property
    public Boolean notIsAddFromExpenseReport {get{ return isAddFromExpenseReport != null ? !isAddFromExpenseReport : true;} private set{}}

    public String pageHeaderTitle {get; set;}

    // will be used to lookup expense-report from filtering
    public pse__Expense__c userExpenseReportSelector {get; set;}


    //
    public pse__Expense_Report__c createdExpenseReport {get; set;}

    public boolean isOperationalUser {get; set;}

    // html class to use when rendering the expense report lookup.
    // for emphasizing error when no expense report is selected
    public String rptLookupErrorClass {get; set;}
    public String expTypeSelectErrorClass {get; set;}
    public String expTypeDateErrorClass {get; set;}
    public String incurredCountryErrorClass {get; set;}
    public String incurredStateErrorClass {get; set;}


    // ----------------------------------------------------
    // - constructor
    // ----------------------------------------------------
    global psaExpenseAddCardTransactionsController()
    {
        this.initialize();
    }

    // ----------------------------------------------------
    // - standard controller constructor
    // ----------------------------------------------------
    global psaExpenseAddCardTransactionsController(ApexPages.StandardController stdController)
    {
        this.initialize();
    }

    // Added by Haribabu to make the changes to display Expense Reports that are in Draft for the logged in User.
    public List<SelectOption> getUserExpenseReports()
    {
        List<SelectOption> options = new List<SelectOption>();

        List<pse__Expense_Report__c> ERList = new List<pse__Expense_Report__c>();
        ERList = [Select Id, name, ownerId,pse__Resource__c, pse__Status__c FROM pse__Expense_Report__c
                   where ownerId =: userinfo.getUserId() and pse__Status__c in ('Draft', 'Rejected')];

        options.add(new SelectOption('','--None--'));

        for (Integer j=0;j<ERList.size();j++)
         {
            options.add(new SelectOption(ERList[j].Id,ERList[j].Name));
         }

        return options;
     }

    private void initialize()
    {
        // initialize...
        expenseReportLoaded = false;
        hasCardTransactions = false;
        dtHolderTo = new pse__Expense_Report__c();
        dtHolderFrom = new pse__Expense_Report__c();
        hasPageError = false;
        pageErrorMessage = '';
        hasPageSuccess = false;
        pageSuccessMessage = '';
        rptLookupErrorClass = '';
        expTypeSelectErrorClass = '';
        expTypeDateErrorClass = '';
        recentlySavedExpenseReports = new pse__Expense_Report__c[]{};

        // determine if this is an operational user
        PermissionSetAssignment[] psasigns = [
                 SELECT PermissionSetId
                   FROM PermissionSetAssignment
                  WHERE AssigneeId= :UserInfo.getUserId()
                    AND PermissionSet.Name like 'PSA_Operations_Only'
                    limit 1];
        isOperationalUser = psasigns != null && psasigns.size() > 0;


        // look for expense report page parameter..
        // ** this drives whether we add to an existing report or manage card transacions
        String expenseReportId = ApexPages.currentPage().getParameters().get('id');
        isAddFromExpenseReport = String.isNotEmpty(expenseReportId);

        lookupExpenseReport(expenseReportId);

        // this page is expected to be called from an expense report, with a specified expenseReport id
        // if there is currently no expense report loaded...show an error
        if (!expenseReportLoaded && isAddFromExpenseReport) {
            hasPageError = true;
            pageErrorMessage = 'Missing required expense report to associate card transaction with.';
            return;
        }

        // define the page heading
        pageHeaderTitle = isAddFromExpenseReport ? 'Add Transactions to Expense Report' : 'Expense Card Transactions';

        /*
            // initialize speicific card transaction management elements
        */
        if (userExpenseReport == null && !isAddFromExpenseReport)
        {
            // set current resource as our underlying expesnse report
            userExpenseReport = new pse__Expense_Report__c(Name = 'NONE SELECTED!');

            // initialize the object were going to use to allow user to lookup expense report
            userExpenseReportSelector = new pse__Expense__c();

            // lookup current resource and assign it to the underlying expense report
            Contact[] curUserRslt = [select id, name, pse__Salesforce_User__c
                                       from contact
                                      where pse__Salesforce_User__c = :UserInfo.getUserId()];
            if (curUserRslt != null && curUserRslt.size() > 0)
            {
                userExpenseReport.pse__Resource__c = curUserRslt[0].id;
            }

            // initialize object to allow for creating a new expense report
            createdExpenseReport = new pse__Expense_Report__c();
            if (curUserRslt != null && curUserRslt.size() > 0)
            {
                createdExpenseReport.pse__Resource__c = curUserRslt[0].id;
            }
            hasExpReportErr = false;
            showExpenseReportModal = false;
            expReportErrMsg = '';

        }


       // verify report status is allowed
        Set<String> allowedStatuses = new Set<String>{
            'Draft',
            'Rejected'
        };


        // raise error when adding from expense report that is not in draft or rejected status
        if(isAddFromExpenseReport && userExpenseReport != null)
        {

            if (!allowedStatuses.contains(userExpenseReport.pse__Status__c))
            {
                addPageErrorMessage('Card transactions can only be associated with Draft or Rejected expense reports!');
                hideCardTransactionTable = true;
                return;
            }
        }


        loadUserCardTransactions();

    }

    public Boolean hideCardTransactionTable {get{
        if (hideCardTransactionTable == null) {
            hideCardTransactionTable = false;
        }
        return hideCardTransactionTable;
        } set;}

    // ----------------------------------------------------
    // Fetch expense report by id!
    // ----------------------------------------------------
    private void lookupExpenseReport(String expReportId)
    {
        if (String.isNotEmpty(expReportId))
        {
            // lookup
            pse__Expense_Report__c[] ersById = [
                select Id,
                       Name,
                       pse__Billable__c,
                       pse__Resource__c,
                       pse__Resource__r.Name,
                       pse__First_Expense_Date__c,
                       pse__Resource__r.PSA_Home_Country__c,
                       pse__Status__c,
                       pse__Description__c
                  from pse__Expense_Report__c
                 where id = :expReportId
            ];

            if (ersById != null && ersById.size() > 0)
            {
                userExpenseReport = ersById[0];
                expenseReportLoaded = true;
            }
            else
            {
                expenseReportLoaded = false;
            }
        }
    }

    // ----------------------------------------------------
    // Retrieves card transactions based on filter options
    //
    // ----------------------------------------------------
    public void loadUserCardTransactions()
    {
        //
        // an 'in-memory' expense report with a resource is required for loading transactions
        //
        if (userExpenseReport != null && userExpenseReport.pse__Resource__c != null)
        {
            // trigger the removal of any existing page alerts
            clearPageErrorMessage();

            // Initialize our totals/summation logic container
            //sumTransactionAmount = new PSA_Card_Transaction__c(PSA_Amount_in_Original_Currency__c = 0);

            // Initialize our wrappers displayed in the UI
            cardTransactionWrappers = new PSACardTransactionWrapper[]{};

            // These are the columns were going to retrieve from the PSA_CARD_TRANSACTION
            // using the cusomized WHERE clause based on our filter
            String[] psaCardTransactionColumns = new String[]{
                  'Id',
                  'CurrencyIsoCode',
                  'Name',
                  'OwnerId',
                  'PSA_Amount_in_Original_Currency__c',
                  'PSA_Amount_in_Billing_Currency__c',
                  'PSA_Assigned_Itemized_Amount__c',
                  'PSA_Remaining_Transaction_Amount__c',
                  'PSA_EmployeeId__c',
                  'PSA_Expense_Type__c',
                  'PSA_FX__c',
                  'PSA_Expense_Report__c',
                  'PSA_Merchant_Country_Code__c',
                  'PSA_Merchant_Name__c',
                  'PSA_Merchant_Postal_Code__c',
                  'PSA_Merchant_State_Province__c',
                  'PSA_Posting_Date__c',
                  'PSA_Processor_Transaction_Id__c',
                  'PSA_Salesforce_User__c',
                  'PSA_Status__c',
                  'PSA_Incurred_Country__c',
                  'PSA_Incurred_State_Province__c',
                  'PSA_Charge_Type__c',
                  'PSA_Resource__c',
                  'PSA_Resource_Inactive__c',
                  'PSA_Previously_Entered__c',
                  'PSA_Invalid_Transaction__c',
                  'PSA_Operations_Review__c',
                  'PSA_Operations_Review_Reason__c',
                  'PSA_Operations_Review_Comments__c',
                  'PSA_Discard__c',
                  'PSA_Transaction_Date__c',
                  'PSA_Transaction_Id__c '
            };

            // generate the soql for retrieving card transactions
            String soql = '';
            soql += ' SELECT ' + String.join(psaCardTransactionColumns, ',') + ', ';

            soql += '   ( SELECT Id, ';
            soql += '            Name, ';
            soql += '            BodyLength, ';
            soql += '            ParentId ';
            soql += '       FROM Attachments ) ';

            soql += '   FROM PSA_Card_Transaction__c ';
            soql += '  WHERE PSA_Resource__c = \'' + userExpenseReport.pse__Resource__c + '\'';
            soql += '    AND PSA_Status__c <> \'Assigned\' ';
            soql += '    AND PSA_Operations_Review__c <> true ';
            soql += '    AND PSA_Previously_Entered__c <> true ';
            soql += '    AND PSA_Invalid_Transaction__c <> true ';
            soql += '    AND PSA_Discard__c <> true ';
            soql += '    AND PSA_Charge_Type__c <> \'Personal\' ';

            if (String.isNotEmpty(filterStartDate) && filterStartDate.length() == 10)
            {
                soql += ' AND PSA_Transaction_Date__c >= ' + filterStartDate;
            }
            if (String.isNotEmpty(filterEndDate) && filterEndDate.length() == 10)
            {
                soql += ' AND PSA_Transaction_Date__c <= ' + filterEndDate;
            }

            // retrieve unassigned card transactions ITEMS!!!
            PSA_Card_Transaction__c[] userCardTransactions = Database.query(soql);

            // populate our wrapper we display in the page
            // and perform our summations...
            if (userCardTransactions != null && userCardTransactions.size() > 0)
            {
                for (PSA_Card_Transaction__c pct : userCardTransactions)
                {
                    cardTransactionWrappers.add(new PSACardTransactionWrapper(pct));

                    // maintain totals
                    //sumTransactionAmount.PSA_Amount_in_Original_Currency__c += pct.PSA_Amount_in_Original_Currency__c != null ? pct.PSA_Amount_in_Original_Currency__c : 0;
                }
            }

            // set our convenient indicator
            hasCardTransactions = userCardTransactions != null && userCardTransactions.size() > 0;
        }
    }

// *******************************************************************************************
/*

*/
    // -- new convenient method for retrieving card trans by id...
    public PSA_Card_Transaction__c findCardTransById(String cardTransId)
    {
        PSA_Card_Transaction__c[] cardTrans = [
            select Id,CurrencyIsoCode,Name,OwnerId,PSA_Assigned_Itemized_Amount__c, PSA_Remaining_Transaction_Amount__c, PSA_Amount_in_Original_Currency__c,PSA_Amount_in_Billing_Currency__c,PSA_EmployeeId__c,PSA_Expense_Type__c,PSA_FX__c,PSA_Expense_Report__c,PSA_Merchant_Country_Code__c,PSA_Merchant_Name__c,PSA_Merchant_Postal_Code__c,PSA_Merchant_State_Province__c,PSA_Posting_Date__c,PSA_Processor_Transaction_Id__c,PSA_Salesforce_User__c,PSA_Status__c,PSA_Incurred_Country__c,PSA_Incurred_State_Province__c,PSA_Charge_Type__c,PSA_Resource__c,PSA_Resource_Inactive__c,PSA_Previously_Entered__c, PSA_Invalid_Transaction__c,
            PSA_Operations_Review__c,PSA_Operations_Review_Reason__c,PSA_Operations_Review_Comments__c,PSA_Discard__c,PSA_Transaction_Date__c,PSA_Transaction_Id__c
            from PSA_Card_Transaction__c
            where id = :cardTransId
        ];

        return (cardTrans != null && cardTrans.size() > 0) ? cardTrans[0] : null;
    }
    // -- new convenient method for retrieving expense by id...
    public pse__Expense__c findExpenseById(String expenseId)
    {
        pse__Expense__c[] expenses = [
            select Id,
                    CurrencyIsoCode,
                    pse__Amount__c,
                    GW_Card_Reimbursement_Amount__c,
                    pse__Type__c,
                    pse__Project__c,
                    pse__Description__c,
                    pse__Expense_Date__c,
                    pse__Expense_Report__c,
                    pse__Approved__c,
                    pse__resource__c,
                    PSA_Card_Transaction__c,
                    PSA_GW_Card__c,
                    pse__Admin_Global_Edit__c,
                    pse__Audit_Notes__c,
                    pse__non_reimbursible__c,
                    PSA_Incurred_Country__c,
                    PSA_Incurred_State_Province__c,
                    pse__Exchange_Rate_Resource_Defined__c
            from pse__Expense__c
            where id = :expenseId
        ];
        return (expenses != null && expenses.size() > 0) ? expenses[0] : null;
    }

    // -- new action function and params to map a specific card transaction to a specific expense id
    public String cardTransIdToMap {get; set;}
    public String expenseIdToMap {get; set;}
    public String prevCardTransMap {get; set;} // when previous card transaction is checked or not....
    public void mapTransactionToExpense()
    {
        clearPageErrorMessage();

        // - place to revert to when we catch errors!
        Savepoint mapppingSavePoint = Database.setSavepoint();

        try
        {
            // true when previously enterted checkbox is checked on the card transaction when matching!
            Boolean isPrevious = String.isNotEmpty(prevCardTransMap) && prevCardTransMap == 'true';

            if (String.isNotEmpty(cardTransIdToMap) && String.isNotEmpty(expenseIdToMap))
            {

                // lookup records
                PSA_Card_Transaction__c cardTrans = findCardTransById(cardTransIdToMap);
                pse__Expense__c expenseItem = findExpenseById(expenseIdToMap);


                if (cardTrans != null && expenseItem != null)
                {
                    // ....
                    // TODO..... update expense and card ???
                    // ............ what kind of mapping logic?
                    // ............ Should card trans overwrite expense fields?
                    // ............ or only write ones, not specified?
                    // ............

                    //expenseItem.GW_Card_Reimbursement_Amount__c = cardTrans.PSA_Amount_in_Billing_Currency__c;
                    expenseItem.GW_Card_Reimbursement_Amount__c = cardTrans.PSA_Amount_in_Billing_Currency__c;
                    expenseItem.PSA_GW_Card__c                  = true; // maybe this is needed???
                    expenseItem.PSA_Card_Transaction__c         = null; // clear so we can update amounts...and get around validation rule!
                    expenseItem.pse__Non_Reimbursible__c        = true; //  force the non-reimbursable checkbox to true if a Credit Card transaction is matched?

                    // when approved skip these so if included in invoice skip this?????
                    if (expenseItem.pse__Approved__c != true)
                    {
                        expenseItem.pse__Expense_Date__c = cardTrans.PSA_Transaction_Date__c;
                        expenseItem.CurrencyIsoCode = cardTrans.CurrencyIsoCode;
                        expenseItem.pse__Amount__c = cardTrans.PSA_Amount_in_Billing_Currency__c;   // default (not itemized)

                        if (String.isEmpty(expenseItem.pse__Description__c))
                        {
                            expenseItem.pse__Description__c = psaExpenseMatchCardTransactionController.buildCardTransactionDescription(cardTrans);
                        }
                    }

                    // create temporary permission when expense item is approved
                    if (expenseItem.pse__Approved__c == true)
                    {
                        createTempPermission(expenseItem);
                    }

// --- to get around VR rule ... we will update the matched expense and amount first....then set the card trans id!
                    update expenseItem;

// ---- NOW WE CAN ASSOCIATE AND MARK CARD TRANS AS ASSIGNED
                    // ** associate expense and card transaction
                    expenseItem.PSA_Card_Transaction__c = cardTrans.id;
                    expenseItem.PSA_GW_Card__c = true;

                    // ** mark card transaction as assigned
                    cardTrans.PSA_Status__c = 'Assigned';
                    // .... and previously entered if specified!
                    if (isPrevious) {
                        cardTrans.PSA_Previously_Entered__c = true;
                    }

                    update expenseItem;
                    update cardTrans;

                    // remove temporary permission when expense item is approved
                    if (expenseItem.pse__Approved__c == true)
                    {
                        removeTempPermission();
                    }
                }
                else
                {
                    // something went wrong looking up by id...perhaps throw an exception in the lookup and catch here?
                    addPageErrorMessage('Error: Missing required card transaction or expense.');
                }
            }
            else
            {
                // our values are not current set
                addPageErrorMessage('Error: Match logic missing required card transaction and/or expense id.');
            }

            // clear input...to ensure they are passed from ui, and not hanging out in the page state
            this.cardTransIdToMap = '';
            this.expenseIdToMap = '';
        }
        catch(Exception e)
        {
            Database.rollback(mapppingSavePoint);
            addPageErrorMessage('ERROR '+ e.getMessage());
        }
    }

    @TestVisible  private Pse__Permission_Control__c pcResReq = null;

    /*********************************************************************************************
    // # creates a temporary permission control allowing the user to create resource requests
    // # Ensures the PSA permission control validation doesn't fail when creating projects
    *********************************************************************************************/
    @TestVisible private void createTempPermission(pse__Expense__c expenseItem) {
        // inject our permission set!
        if (pcResReq == null) {
            pcResReq = new Pse__Permission_Control__c(
                pse__User__c                   = UserInfo.getUserId() ,
                pse__Expense_Ops_Edit__c       = true,
                pse__Project__c                = expenseItem.pse__Project__c,
                pse__Cascading_Permission__c   = true
            );
            insert pcResReq;
        }
    }

    /*********************************************************************************************
    // # removes the temporary permission control
    *********************************************************************************************/
    @TestVisible private void removeTempPermission() {
        if (pcResReq != null) {
            delete pcResReq;
            pcResReq = null;
        }
    }



    // adds a singe card transaction
    public String cardTansIdToAdd {get; set;}
    public void addSingleItemToExpenseReport()
    {

//system.debug(' cardTansIdToAdd: ' + cardTansIdToAdd);

        //lookup the card trans id to add
        PSACardTransactionWrapper[] tadd = new PSACardTransactionWrapper[]{};
        for (PSACardTransactionWrapper cardTrans : cardTransactionWrappers)
        {
            if (cardTrans.cardTransaction.id == cardTansIdToAdd)
            {
                cardTrans.selected = true;
                tadd.add(cardTrans);
                break;
            }
        }

        if (tadd != null && tadd.size() > 0)
        {
            handleAddToExpenseReport(tadd);
        }
    }

// *******************************************************************************************

    // --- collection of psa incurred country ids which require a state
    private Set<Id> countryIdsRequiringStates {
        get
        {
            if (countryIdsRequiringStates == null)
            {
                // load the set with ids for United States and Canada countries!
                countryIdsRequiringStates = new Set<Id>();
                for (pw_cc__CountryObject__c cobj : [
                        select Id,pw_cc__IsoCode_3__c, name
                          from pw_cc__CountryObject__c
                         where name in :(new Set<String>{'United States', 'Canada'})])
                {
                    countryIdsRequiringStates.add(cobj.id);
                }
            }
            return countryIdsRequiringStates;
        }
        private set;
    }


    // Expense types requiring attendees, note lower case...
    // String expType = 'Meals - GW Emp Only';
    // lowerExpenseTypesRequiringAttendees.contains(expType.toLowerCase())
    private Set<String> lowerExpenseTypesRequiringAttendees = new Set<String>{
        'meals - gw emp only',
        'meals - with 3rd parties',
        'entertain - gw emp only',
        'entertain - with 3rd parties'
    };



    // ----------------------------------------------------
    // ...logic behind adding selected transactions to the expense report
    // ** 'Add To Expense Report'
    // ----------------------------------------------------
    public void addToExpenseReport()
    {
        // punt to the handler!
        handleAddToExpenseReport(cardTransactionWrappers);
    }

    // -- new handler allowing for processing in bulk or one at a time
    private void handleAddToExpenseReport(PSACardTransactionWrapper[] inCards)
    {
        clearPageErrorMessage();

        // loop over the selected PSACardTransactionWrapper

        // for collecting the selected card transactions to update
        PSA_Card_Transaction__c[] selectedCardTransactions = new PSA_Card_Transaction__c[]{};

        // for collecting the 'billable' transactions (we'll make these expense items, then update them)
        //PSA_Card_Transaction__c[] billableTransactions = new PSA_Card_Transaction__c[]{};
        PSACardTransactionWrapper[] billableTransactions = new PSACardTransactionWrapper[]{};

        // for collecting the 'non-billable' transactions (we'll make these expense items, then update them)
        //PSA_Card_Transaction__c[] nonBillableTransactions = new PSA_Card_Transaction__c[]{};
        PSACardTransactionWrapper[] nonBillableTransactions = new PSACardTransactionWrapper[]{};

        // lookup expense report information.....
        Map<Id, pse__Expense_Report__c> expRptMap = new Map<Id, pse__Expense_Report__c>();
        Set<Id> expenseReportIds = new Set<Id>();

        if (userExpenseReport != null && userExpenseReport.id != null)
        {
            expenseReportIds.add(userExpenseReport.id);
        }

        // gather expense reports for each line
        for (PSACardTransactionWrapper pct : inCards)
        {
            if (pct.selected && pct.cardTransaction.PSA_Expense_Report__c != null)
            {
                if (pct.cardTransaction.PSA_Expense_Report__c != null)
                {
                    expenseReportIds.add(pct.cardTransaction.PSA_Expense_Report__c);
                }
            }
        }
        if (expenseReportIds != null && expenseReportIds.size() > 0)
        {
            expRptMap = new Map<Id, pse__Expense_Report__c>([
                select id,
                        pse__Billable__c
                from pse__Expense_Report__c
                where id in :expenseReportIds
            ]);
        }

        //
        for (PSACardTransactionWrapper pct : inCards)
        {
            if (pct.selected && !pct.isStale)
            {
                boolean expBillable = pct.billable;


                String[] pgErrors = new String[]{};

                // verify an expense report is set for each selected line on the 'Expense Card Transactions'
                // note this is only needed for the 'Expense Card Transaction' screen
                if (notIsAddFromExpenseReport &&
                    pct.cardTransaction.PSA_Expense_Report__c == null &&
                    pct.previouslyEntered == false &&
                    pct.personal == false &&
                    pct.invalidTransaction == false)
                {
                    rptLookupErrorClass = 'rptlookup-error';
                    pgErrors.add('ERROR: Please specify an expense report for all selected transactions.');
                    //addPageErrorMessage('ERROR: Please specify an expense report for all selected transactions.');
                    //return;
                }

                // verify a psa expense type is selected, when not personal and not previous and not rejected or declined.....
                if (String.isEmpty(pct.cardTransaction.PSA_Expense_Type__c)
                                && !pct.previouslyEntered
                                && !pct.personal
                                && !pct.invalidTransaction)
                {
                    expTypeSelectErrorClass = 'rptlookup-error';
                    pgErrors.add('ERROR: Please select an expense type for all selected transactions.');
                    //addPageErrorMessage('ERROR: Please select an expense type for all selected transactions.');
                    //return;
                }
                // --- when expense type requires attendees
                else if (pct.cardTransaction.PSA_Expense_Type__c != null &&
                         lowerExpenseTypesRequiringAttendees.contains(pct.cardTransaction.PSA_Expense_Type__c.toLowerCase()) &&
                         (pct.expense == null || String.isEmpty(pct.expense.PSA_Attendees__c)))
                {
                    expTypeSelectErrorClass = 'rptlookup-error';
                    pgErrors.add('ERROR: Attendees are required for all expense types of "' + pct.cardTransaction.PSA_Expense_Type__c + '" please expand the row and include attendees in the textarea provided.');
                }

                // require a location....
                if (!pct.previouslyEntered && !pct.personal && !pct.invalidTransaction)
                {
                    if (pct.expense == null)
                    {
                        incurredCountryErrorClass = 'rptlookup-error';
                        pgErrors.add('ERROR: Please specify an incurred country for all selected transactions.');
                    }
                    else if (pct.expense.PSA_Incurred_Country__c == null)
                    {
                        incurredCountryErrorClass = 'rptlookup-error';
                        pgErrors.add('ERROR: Please specify an incurred country for all selected transactions.');
                    }
                    // when location requires a state/prov
                    else if ( countryIdsRequiringStates.contains(pct.expense.PSA_Incurred_Country__c) &&
                              pct.expense.PSA_Incurred_State_Province__c == null )
                    {
                        incurredStateErrorClass = 'rptlookup-error';
                        pgErrors.add('ERROR: Please specify an incurred state or province for all transactions incurring in the United States or Canada.');
                    }

                }


                // return with all/any errors
                if (pgErrors != null && pgErrors.size() > 0)
                {
                    addPageErrorMessage(String.join(pgErrors, '<br/>'));
                    return;
                }

                // ---- update card transaction based on selected options:

                // previously entered records get marked accordingly
                if (pct.previouslyEntered == true)
                {
                    pct.cardTransaction.PSA_Previously_Entered__c = true;
                }

                if (pct.invalidTransaction == true)
                {
                    pct.cardTransaction.PSA_Invalid_Transaction__c = true;
                }


                // personal transactions... // we change the charge-type
                if (pct.personal == true)
                {
                    pct.cardTransaction.PSA_Charge_Type__c = 'Personal';
                }

                // non personal/ rejecte or declined / previously enetered transactions .... will not become billable or non-billable expense items
                if (pct.personal == false && pct.previouslyEntered == false && pct.invalidTransaction == false)
                {

                    pct.cardTransaction.PSA_Charge_Type__c = 'Company';

                    // set the expense report on the card transaction
                    // NOTE: only needed from the 'Add Transactions To Expense Report' screen
                    //       when linked from expense report page
                    if (isAddFromExpenseReport)
                    {
                        pct.cardTransaction.PSA_Expense_Report__c = userExpenseReport.id;
                    }

                    // billable based on underlying expense report
                    if (expRptMap.containsKey(pct.cardTransaction.PSA_Expense_Report__c))
                    {
                        expBillable = expRptMap.get(pct.cardTransaction.PSA_Expense_Report__c).pse__Billable__c;
                    }


                    // collect the billable and non-billable transactions to create expense items from
                    if (pct.billable && expBillable)
                    {
                        billableTransactions.add(pct);
                    }
                    else
                    {
                        nonBillableTransactions.add(pct);
                    }
                }

                selectedCardTransactions.add(pct.cardTransaction);
            }
        }

        this.persist(selectedCardTransactions, billableTransactions, nonBillableTransactions, null, false);
    }

    // ----------------------------------------------------
    // ...logic behind adding an itemized transaction to the expense report
    //    the expense report
    // ----------------------------------------------------
    public void addItemizedToExpenseReport()
    {
        clearPageErrorMessage();
        try
        {
            // validate the itemized data
            if (itemizedTransWrapper.isValid())
            {
                // Get the itemized transaction objects
                PSA_Card_Transaction__c cardTrans = itemizedTransWrapper.cardTransaction;

                PSACardTransactionWrapper[] billableTransactions = new PSACardTransactionWrapper[]{};

                // collect 'non-billable' transactions (we'll make these non billable expense items)
                PSACardTransactionWrapper[] nonBillableTransactions = new PSACardTransactionWrapper[]{};

                // collect 'personal' transactions, need to get flagged to not goto intact
                PSA_Card_Transaction__c[] personalTransactions = new PSA_Card_Transaction__c[]{};

                // grab the amounts to help us perform our billling proportion logic
                Decimal totalAmountInOriginal = cardTrans.PSA_Amount_in_Original_Currency__c;
                Decimal totalAmountInBilling  = cardTrans.PSA_Amount_in_Billing_Currency__c != null ? cardTrans.PSA_Amount_in_Billing_Currency__c : totalAmountInOriginal;

                // ensure at least one billable itemized amount is included.....
                Boolean hasExpenseItemRow = false;
                for (PSACardTransactionWrapper pctw : itemizedTransWrapper.itemizedTransactions) {
                    if (!pctw.personal) {
                        hasExpenseItemRow = true;
                        break;
                    }
                }
                if (!hasExpenseItemRow) {
                    addPageErrorMessage('Error: Please designate the entire card transaction as personal, or include a non personal amount in the itemized transaction.');
                    return;
                }

                // ###############################
                // lookup expense report billable information.....
                Map<Id, pse__Expense_Report__c> expRptMap = new Map<Id, pse__Expense_Report__c>();
                Set<Id> expenseReportIds = new Set<Id>();

                if (userExpenseReport != null && userExpenseReport.id != null)
                {
                    expenseReportIds.add(userExpenseReport.id);
                }

                if (userExpenseReportSelector != null && userExpenseReportSelector.pse__Expense_Report__c != null)
                {
                    expenseReportIds.add(userExpenseReportSelector.pse__Expense_Report__c);
                }

                // # NOW NEEDED FOR ITEMIZING, LOAD EXPENSE REPORTS (BASICALLY IF THEY ARE BILLABLE...)
                for (PSACardTransactionWrapper pctw : itemizedTransWrapper.itemizedTransactions)
                {
                    PSA_Card_Transaction__c itemizedLine = pctw.cardTransaction;
                    if (itemizedLine != null && itemizedLine.PSA_Expense_Report__c != null)
                    {
                        expenseReportIds.add(itemizedLine.PSA_Expense_Report__c);
                    }
                }
                if (userExpenseReport != null)
                {
                    expenseReportIds.add(userExpenseReport.Id);
                }
                // load our expense report map
                if (expenseReportIds != null && expenseReportIds.size() > 0)
                {
                    expRptMap = new Map<Id, pse__Expense_Report__c>([
                        select id,
                                pse__Billable__c
                        from pse__Expense_Report__c
                        where id in :expenseReportIds
                    ]);
                }

                // system.debug('\n ########## \n expRptMap > ' + expRptMap);
                // ###############################

                for (PSACardTransactionWrapper pctw : itemizedTransWrapper.itemizedTransactions)
                {
                    PSA_Card_Transaction__c itemizedLine = pctw.cardTransaction;


                    Double itemAmt = itemizedLine.PSA_Amount_in_Original_Currency__c;
                    //if ( itemAmt != null && itemizedLine.PSA_Assigned_Itemized_Amount__c > 0 )
                    //{
                    //    itemAmt = itemAmt - itemizedLine.PSA_Assigned_Itemized_Amount__c;
                    //}
                    // calculate amount in billing currency
                    if (totalAmountInOriginal != null &&
                        totalAmountInOriginal > 0 &&
                        totalAmountInOriginal >= itemAmt &&
                        totalAmountInBilling != null)
                    {
                        /*
                            GW Card Reimbursement Amount = Amount in Billing Currency * (Amount field from “Itemize Transactions - Multiple Expenses screen” / Transaction.Amount in Original Currency)
                        */

                        //system.debug(' \n\n ENTERING THIS NOW ????? ' +
                        //                '\n totalAmountInBilling:' + totalAmountInBilling +
                        //                '\n itemAmt:' + itemAmt +
                        //                '\n totalAmountInOriginal' + totalAmountInOriginal +
                        //                '\n amt in bill curr? ' + totalAmountInBilling * (itemAmt / totalAmountInOriginal) +
                        //                '\n ------------------- \n');

                        itemizedLine.PSA_Amount_in_Billing_Currency__c =  totalAmountInBilling * (itemAmt / totalAmountInOriginal);

                    }
                    else
                    {
                        addPageErrorMessage('Error: Attempt to itemize billing amount when total Amount in Original or total Amount in Billing is invalid.');
                        return;
                    }


                    // verify an expense report is set for each selected line on the 'Expense Card Transactions'
                    // note this is only needed for the 'Expense Card Transaction' screen
                    if (notIsAddFromExpenseReport && itemizedLine.PSA_Expense_Report__c == null && !pctw.personal)
                    {
                        rptLookupErrorClass = 'rptlookup-error';
                        addPageErrorMessage('ERROR: Please specify an expense report for all selected transactions.');
                        return;
                    }

                    // verify a psa expense type is selected.
                    if (String.isEmpty(itemizedLine.PSA_Expense_Type__c) && !pctw.personal)
                    {
                        expTypeSelectErrorClass = 'rptlookup-error';
                        addPageErrorMessage('ERROR: Please select an expense type for all itemized transactions.');
                        return;
                    }

                    // verify expense dates are set
                    if (itemizedLine.PSA_Transaction_Date__c == null)
                    {
                        expTypeDateErrorClass = 'rptlookup-error';
                        addPageErrorMessage('ERROR: Please specify an expense date for all itemized transactions.');
                        return;
                    }

                    // require a location....
                    // --- // verify incurred country
                    // --- // verify state, if needed....
                    if (!pctw.previouslyEntered && !pctw.personal && !pctw.invalidTransaction)
                    {
                        if (pctw.expense == null)
                        {
                            //expTypeSelectErrorClass = 'rptlookup-error';
                            addPageErrorMessage('ERROR: Please specify an incurred country for all itemized transactions.');
                            return;
                        }
                        else if (pctw.expense.PSA_Incurred_Country__c == null)
                        {
                            //expTypeSelectErrorClass = 'rptlookup-error';
                            addPageErrorMessage('ERROR: Please specify an incurred country for all itemized transactions.');
                            return;
                        }
                        // when location requires a state/prov
                        else if ( countryIdsRequiringStates.contains(pctw.expense.PSA_Incurred_Country__c) &&
                                  pctw.expense.PSA_Incurred_State_Province__c == null )
                        {
                            //expTypeSelectErrorClass = 'rptlookup-error';
                            addPageErrorMessage('ERROR: Please specify an incurred state or province for all transactions incurring in the United States or Canada.');
                            return;

                        }

                    }

                        // should charge type be 'itemized' ??
                        //cardTrans.PSA_Charge_Type__c = 'Itemized';

                    // set expense report based on page view
                    if (isAddFromExpenseReport)
                    {
                        itemizedLine.PSA_Expense_Report__c = userExpenseReport.id;
                        cardTrans.PSA_Expense_Report__c = userExpenseReport.id;
                    }

                    // billable based on underlying expense report
                    boolean expBillable = true;
                    if (expRptMap.containsKey(itemizedLine.PSA_Expense_Report__c))
                    {
                        expBillable = expRptMap.get(itemizedLine.PSA_Expense_Report__c).pse__Billable__c;
                    }

                    // collect the billable and non-billable / personal transactions to create expense items from
                    if (pctw.billable && expBillable)
                    {
                        billableTransactions.add(pctw);
                    }

                    else
                    {
                        if (pctw.personal) {
                            personalTransactions.add(itemizedLine);
                        } else {
                            nonBillableTransactions.add(pctw);
                        }


                    }

                }

                this.persist(new PSA_Card_Transaction__c[]{cardTrans}, billableTransactions, nonBillableTransactions, personalTransactions, true);
            }
        }
        catch(Exception e)
        {
            addPageErrorMessage(e.getMessage());
        }
    }




    // ----------------------------------------------------
    // renders itemized details ...
    // ----------------------------------------------------
    //
    // action behind itemize button on vf page
    //
    public void itemizeUserCardTransaction()
    {
        clearPageErrorMessage();
        hasItemizedCardTransaction = false;

        isItemizedTransactionSaved = false;
        transactionIdSaved = null;

        // generate our itemized transactions to work with based on the specific user transaction
        if (String.isNotEmpty(transactionIdToItemize))
        {
            transactionIdSaved = transactionIdToItemize;

            //system.debug('\n\n ** transactionIdToItemize > ' + transactionIdToItemize);

            // look up transaction from user card transactions
            //PSA_Card_Transaction__c selectedTransaction = null;

            PSACardTransactionWrapper selectedTransactionWrapper = null;

            for (PSACardTransactionWrapper pct : cardTransactionWrappers)
            {
                if (pct.cardTransaction.Id == transactionIdToItemize)
                {
                    // found it
                    //selectedTransaction = pct.cardTransaction;
                    // grab expense??
                    selectedTransactionWrapper = pct;


system.debug(' from wrapper....expense state ??? ' + pct.expense.PSA_Incurred_State_Province__c);

                    break;
                }
            }

            //system.debug('\n\n ** selectedTransaction > ' + selectedTransaction);
            if (selectedTransactionWrapper != null)
            {
                itemizedTransWrapper = new PSAItemizedTransactionWrapper(selectedTransactionWrapper);
                hasItemizedCardTransaction = true;
            }
            transactionIdToItemize = null; // clear this out...
        }
    }

    // ----------------------------------------------------
    // logic behind the canel of itemizations!
    // ----------------------------------------------------
    public void cancelItemizeUserCardTransaction()
    {
        clearPageErrorMessage();
        hasItemizedCardTransaction = false;

        isItemizedTransactionSaved = false;
        transactionIdSaved = null;

    }


    // ----------------------------------------------------
    // Action behind adding another itemization line to the page...'add expense line'
    // generates a new transaction item in the itemized expense
    // transactions
    // ----------------------------------------------------
    public void addItemizedLine()
    {
        clearPageErrorMessage();

        if (itemizedTransWrapper != null && itemizedTransWrapper.itemizedTransactions != null)
        {
            PSA_Card_Transaction__c itemtrans = (itemizedTransWrapper.cardTransaction != null) ? itemizedTransWrapper.cardTransaction.clone() : new PSA_Card_Transaction__c();
            itemtrans.id = null;
            itemtrans.PSA_Amount_in_Original_Currency__c = 0;

            PSACardTransactionWrapper cardTransItem = new PSACardTransactionWrapper(itemtrans);

            // clone the current expense row....
            if (itemizedTransWrapper.origWrapperToItemize != null && itemizedTransWrapper.origWrapperToItemize.expense != null)
            {
                pse__Expense__c itemizedExpense = itemizedTransWrapper.origWrapperToItemize.expense.clone();
                itemizedExpense.id = null;

                cardTransItem.expense = itemizedExpense;
            }

            itemizedTransWrapper.addNewTransaction(cardTransItem);
        }
    }

    // ----------------------------------------------------
    // Action behind 'delete expense line'
    // removes selected itemized transactions
    // ----------------------------------------------------
    public void deleteSelectedItemizedLines()
    {
        clearPageErrorMessage();
        boolean hasSelectedRow = false;

        if (itemizedTransWrapper != null && itemizedTransWrapper.itemizedTransactions != null)
        {
            // remove the selected rows...(trick here is to iterate over the list in reverse and delete as we go)
            for ( Integer i = itemizedTransWrapper.itemizedTransactions.size() - 1; i >= 0; --i )
            {
                PSACardTransactionWrapper cardTrans = itemizedTransWrapper.itemizedTransactions[i];

                if (cardTrans.selected == true)
                {
                    hasSelectedRow = true;
                    //rowsToPurge.add(i);
                    itemizedTransWrapper.itemizedTransactions.remove(i); // remove the selected row

                }
            }
        }
        if (!hasSelectedRow)
        {
            addPageErrorMessage('Please select a row to delete');
        }
        else
        {
            itemizedTransWrapper.sumItemizedAmounts();
        }
    }

    /// -- page alerts


    private void clearPageErrorMessage()
    {
        hasPageError = false;
        pageErrorMessage = '';

        hasPageSuccess = false;
        pageSuccessMessage = '';

        rptLookupErrorClass = '';
        expTypeSelectErrorClass = '';
        expTypeDateErrorClass = '';

        incurredCountryErrorClass = '';
        incurredStateErrorClass = '';

        // reset....
        recentlySavedExpenseReports = new pse__Expense_Report__c[]{};

    }

    private void addPageErrorMessage(String msg)
    {
        hasPageError = true;
        pageErrorMessage = msg;
    }

    private void addPageSuccessMessage(String msg)
    {
        hasPageSuccess = true;
        pageSuccessMessage = msg;
    }


    /// ------------------- expense report creation properites

    public String expenseReportAssignmentId {get; set;} // will contain the selected assignment id for the new expene report
    public SelectOption[] userAssignmentSelectOptions {get; set;} // will contain assignments associated with the user
    public String expReportErrMsg {get; set;} // lets the page know the expense report modal dialog error to display
    public boolean hasExpReportErr {get; set;} // lets the page know the expense report modal dialog has an error
    public boolean showExpenseReportModal {get; set;} // lets the page know to render the expense report modal dialog

    // Retrieves assignments associated with the user, used when creating new expense reports
    //
    // Note the option key will be assignmentId:projectId
    private void loadUserAssignmentOptions(Id userId)
    {
        expenseReportAssignmentId  = '';
        userAssignmentSelectOptions = new SelectOption[]{};

        if (userExpenseReport.pse__Resource__c != null)
        {

            //
            // Grab the users assignments, excluding the timeoff projects...
            // inject into our assignment/project picklist
            for (pse__Assignment__c assignment : [
                    select id,
                           name,
                           pse__Project__c,
                           pse__End_Date__c,
                           pse__Start_Date__c,
                           pse__resource__c,
                           pse__Status__c,
                           pse__project__r.pse__project_type__c
                      from pse__Assignment__c
                      where pse__resource__c = :userExpenseReport.pse__Resource__c
                        and pse__Status__c <> 'Closed'
                        and pse__project__r.pse__project_type__c <> 'Time Off'
            ])
            {
                String poraKey = assignment.id + ':' + assignment.pse__Project__c;

                String assignmentDates = 'Assignment: (' + assignment.pse__Start_Date__c.format() + ' - ' + assignment.pse__End_Date__c.format() + ') ';

                String optionValue = assignmentDates + ' ' + assignment.name;

                userAssignmentSelectOptions.add(new SelectOption(poraKey, '' + optionValue));
            }

            //
            // grab the internal projects that 'allow expenses without projects' with future end dates...
            // inject into our assignment/project picklist
            for (pse__Proj__c internalProj :[select id,
                                                    name,
                                                    pse__project_type__c,
                                                    pse__Allow_Expenses_Without_Assignment__c,
                                                    pse__Start_Date__c,
                                                    pse__End_Date__c
                                               from pse__proj__c
                                              where pse__project_type__c = 'Internal'
                                                and pse__Allow_Expenses_Without_Assignment__c = true
                                                and pse__End_Date__c > TODAY])
            {
                String poraKey = '<none>:' + internalProj.id; // note when NONE will be trated as internal project when saving a new expense report

                String projDates = 'Internal Project: (' + internalProj.pse__Start_Date__c.format() + ' - ' + internalProj.pse__End_Date__c.format() + ') ';

                String optionValue = projDates + ' ' + internalProj.name;

                userAssignmentSelectOptions.add(new SelectOption(poraKey, '' + optionValue));
            }

        }
    }


    // ----------------------------------------------------
    // action behind create and showing new expense report
    // ----------------------------------------------------
    public void createAndShowNewExpenseReport()
    {
        try
        {
            // lookup assignments for the specific resource when the modal is popped open
            loadUserAssignmentOptions(userExpenseReport.pse__Resource__c);

            // intialize the object for creating expense reports
            createdExpenseReport = new pse__Expense_Report__c(pse__Resource__c = userExpenseReport.pse__Resource__c);
            showExpenseReportModal = true;
        }
        catch(Exception e)
        {
            addPageErrorMessage('ERROR '+ e.getMessage());
        }

    }

    // ----------------------------------------------------
    // action behind save new expense report
    // ----------------------------------------------------
    public void saveNewExpenseReport()
    {
        // system.debug(' starting saveNewExpenseReport >>> ');

        hasExpReportErr = false;
        expReportErrMsg = '';

        // require fields (may need to incorporate some kind of custom assingment/project)
        //  * resource
        //  * assignment Id /(and or) projectid
        //  * descrption is optional
        if( createdExpenseReport.pse__Resource__c == null ||
            expenseReportAssignmentId == null || expenseReportAssignmentId == '' ||
            expenseReportAssignmentId.split(':').size() != 2 ||
            createdExpenseReport.name == null )
        {
            hasExpReportErr = true;
            expReportErrMsg = 'Please include a name for the expense report.';

            return;
        }

        // seems to be valid....lets try to save
        try
        {

            String[] keys = expenseReportAssignmentId.split(':');


            String assignmentId = keys[0];
            String projectId = keys[1];

            if (assignmentId == '<none>')
            {
                // lookup internal project
                pse__Proj__c[] internalProj = [
                                  select id,
                                         pse__project_type__c,
                                         pse__Allow_Expenses_Without_Assignment__c,
                                         pse__Is_Billable__c,
                                         pse__End_Date__c
                                    from pse__Proj__c
                                   where pse__project_type__c = 'Internal'
                                     and pse__Allow_Expenses_Without_Assignment__c = true
                                     and pse__End_Date__c > TODAY
                                     and id = :projectId];

                if (internalProj == null || internalProj.size() <= 0)
                {
                    hasExpReportErr = true;
                    expReportErrMsg = 'ERROR: No matching internal projects allowing expenses without assignments were found.';
                }
                else
                {
                    createdExpenseReport.pse__Project__c  =  internalProj[0].id;
                    createdExpenseReport.pse__Billable__c =  internalProj[0].pse__Is_Billable__c;
                }

            }
            else
            {
                // lookup assignment based on selected resource/assignment
                pse__Assignment__c[] assignlist = [select id,
                                                          name,
                                                          pse__Resource__c,
                                                          pse__project__c,
                                                          pse__Project__r.pse__Is_Billable__c,
                                                          pse__Is_Billable__c
                                                     from pse__Assignment__c
                                                    where pse__resource__c =: createdExpenseReport.pse__Resource__c
                                                      and id =:assignmentId];

                if (assignlist == null || assignlist.size() <=0)
                {
                    hasExpReportErr = true;
                    expReportErrMsg = 'ERROR: No matching assignments for resource were found.';
                }
                else
                {
                    // set the project and assignment on the expense report were going to create.
                    createdExpenseReport.pse__Project__c    = assignlist[0].pse__project__c;
                    createdExpenseReport.pse__Assignment__c = assignlist[0].id;
                    createdExpenseReport.pse__Billable__c   = assignlist[0].pse__Is_Billable__c;
                }

            }

            if (hasExpReportErr != true && createdExpenseReport.pse__Project__c != null)
            {
                insert createdExpenseReport;

                hasExpReportErr = false;
                expReportErrMsg = '';

                // set the selector, based on the newly created report
                userExpenseReportSelector.pse__Expense_Report__c = createdExpenseReport.id;

                //system.debug('\n\n *** ' + userExpenseReportSelector.pse__Expense_Report__c + '\n\n');

                // reset the expense report...on success....
                showExpenseReportModal =  false; // trigger the page to close the modal!

                // notify of success!
                addPageSuccessMessage('SUCCESS. Expense report has been created.');
            }
        }
        catch(Exception e)
        {
            hasExpReportErr = true;
            expReportErrMsg = e.getMessage();

        }
    }


    // ----------------------------------------------------
    // Logic for applying selected card transactions to a specific expense report
    // ----------------------------------------------------
    public void applySelectedToExpenseReport()
    {
        clearPageErrorMessage();

        boolean isValid = true;

        Id expReportId = userExpenseReportSelector != null ? userExpenseReportSelector.pse__Expense_Report__c : null;
        if (expReportId == null)
        {
            isValid = false;
            rptLookupErrorClass = 'rptlookup-error';
            addPageErrorMessage('Please choose an expense report to apply and try again.');
        }

        if (isValid)
        {
            // collect selected/non-stale cards (we mark them stale when adding to keep the screen from refreshing)

// ***** TODO: // ***** Rewrite the add card transaction page as a single page app using modern frontend framework
// ***** TODO: // ***** routes to include 'add expense', 'itemize', 'expense report'

            PSACardTransactionWrapper[] nonStaleCardTransactionWrappers = new PSACardTransactionWrapper[]{};

            boolean hasSelection = false;
            for (PSACardTransactionWrapper pct : cardTransactionWrappers)
            {
                if (!pct.isStale)
                {
                    nonStaleCardTransactionWrappers.add(pct);
                }

                if (pct.selected)
                {
                    hasSelection = true;
                    pct.cardTransaction.PSA_Expense_Report__c = expReportId;
                }

            }
            if (!hasSelection) {
                isValid = false;
                addPageErrorMessage('Please check the transactions to apply the expense report too and try again.');
            }
            else
            {
                // remove stale transactions
                this.cardTransactionWrappers = nonStaleCardTransactionWrappers;
            }
        }
    }

    // # Generates an itemized transaction record
    // #
    private PSA_Card_Transaction_Item__c[] generateItemizedTransactions(
                             Id masterPsaCardTransId,
                             PSACardTransactionWrapper[] billableTransactions,
                             PSACardTransactionWrapper[] nonBillableTransactions,
                             PSA_Card_Transaction__c[] personalTransactions,
                             boolean fromAmtRemaining)
    {

        // maintain our transaction items
        PSA_Card_Transaction_Item__c[] transItems = new PSA_Card_Transaction_Item__c[]{};

        if (personalTransactions != null && personalTransactions.size() > 0 && masterPsaCardTransId != null) {
            for (PSA_Card_Transaction__c p : personalTransactions) {
                p.PSA_Charge_Type__c = 'Personal';
                transItems.add(initializeCardTransactionItem(masterPsaCardTransId, p));
            }
        }

        if (billableTransactions != null && billableTransactions.size() > 0) {
            for (PSACardTransactionWrapper cw : billableTransactions) {
                cw.cardTransaction.PSA_Charge_Type__c = 'Company';

                // construct transaction
                PSA_Card_Transaction_Item__c cardTransItem = initializeCardTransactionItem(masterPsaCardTransId, cw.cardTransaction);
                cw.cardTransactionItem = cardTransItem;  // write it back to the wrapper

                // use the remaining transaction amount as the amount .....
                if (fromAmtRemaining && cw.cardTransaction.PSA_Remaining_Transaction_Amount__c != null)
                {
                    Decimal remainingAmt = cw.cardTransaction.PSA_Remaining_Transaction_Amount__c;
                    remainingAmt = remainingAmt < 0 ? 0 : remainingAmt;

                    cardTransItem.PSA_Amount_in_Original_Currency__c = remainingAmt;
                    cardTransItem.GW_Card_Reimbursement_Amount__c    = cw.calculateGWCardReimburesementAmount(remainingAmt);
                }

                transItems.add(cardTransItem);
            }
        }

        if (nonBillableTransactions != null && nonBillableTransactions.size() > 0) {
            for (PSACardTransactionWrapper nw : nonBillableTransactions) {
                nw.cardTransaction.PSA_Charge_Type__c = 'Company';

                // construct transaction
                PSA_Card_Transaction_Item__c cardTransItem = initializeCardTransactionItem(masterPsaCardTransId, nw.cardTransaction);
                nw.cardTransactionItem = cardTransItem;  // write it back to the wrapper

                // use the remaining transaction amount as the amount .....
                if (fromAmtRemaining && nw.cardTransaction.PSA_Remaining_Transaction_Amount__c != null)
                {
                    Decimal remainingAmt = nw.cardTransaction.PSA_Remaining_Transaction_Amount__c;
                    remainingAmt = remainingAmt < 0 ? 0 : remainingAmt;

                    cardTransItem.PSA_Amount_in_Original_Currency__c = remainingAmt;
                    cardTransItem.GW_Card_Reimbursement_Amount__c    = nw.calculateGWCardReimburesementAmount(remainingAmt);
                }

                transItems.add(cardTransItem);
            }
        }

        if (transItems != null && transItems.size() > 0)
        {
            insert transItems;
        }

        return transItems;

    }


    // --------------------------------------------------------------------------------------------------------
    // creates the new expense
    // updates card transactions and creates our expenses
    private void persist(PSA_Card_Transaction__c[] selectedCardTransactions,
                         PSACardTransactionWrapper[] billableTransactions,
                         PSACardTransactionWrapper[] nonBillableTransactions,
                         PSA_Card_Transaction__c[] personalTransactions,

                         boolean isItemizing)
    {
        Set<Id> updatedExpenseReportIds = new Set<Id>();

        Savepoint savePoint = Database.setSavepoint();
        try
        {
            Id itemizingCardTransId = null;

            // ## START UPDATE
            if (isItemizing)
            {
                itemizingCardTransId = (selectedCardTransactions != null && selectedCardTransactions.size() > 0)? selectedCardTransactions[0].id : null;
                PSA_Card_Transaction_Item__c[] transItems = generateItemizedTransactions(itemizingCardTransId, billableTransactions, nonBillableTransactions, personalTransactions, false);
            }
            else
            {

// deletedExpCardTransactionItemIds

                // handle case when adding an item to an already itemized transaction
                //
                // --- NOW we need to look for card transactions that are itemizations which are getting added directly to exp rpt....
                PSACardTransactionWrapper[] itemizedBillTrans = new PSACardTransactionWrapper[]{};
                if (billableTransactions != null && billableTransactions.size() > 0)
                {
                    for (PSACardTransactionWrapper w : billableTransactions)
                    {
                        if (!w.isStale && w.cardTransaction.PSA_Assigned_Itemized_Amount__c > 0)
                        {
                            w.useRemainingAmtForExpense  = true;

                            itemizedBillTrans.add(w);
                        }
                    }
                }
                PSACardTransactionWrapper[] itemizedNoBillTrans = new PSACardTransactionWrapper[]{};
                if (nonBillableTransactions != null && nonBillableTransactions.size() > 0)
                {
                    for (PSACardTransactionWrapper w : nonBillableTransactions)
                    {
                        if (!w.isStale && w.cardTransaction.PSA_Assigned_Itemized_Amount__c > 0)
                        {
                            w.useRemainingAmtForExpense  = true;

                            itemizedNoBillTrans.add(w);
                        }
                    }
                }
                PSA_Card_Transaction__c[] itemizedPersonalTransactions = new PSA_Card_Transaction__c[]{};
                if (personalTransactions != null && personalTransactions.size() > 0)
                {
                    for (PSA_Card_Transaction__c d : personalTransactions)
                    {
                        d.PSA_Expense_Report__c = ''; // clear for itemized
                        itemizedPersonalTransactions.add(d);
                    }
                }

                if (itemizedBillTrans.size() > 0 || itemizedNoBillTrans.size() > 0 || itemizedPersonalTransactions.size() > 0)
                {
                    Id cardTransId = (selectedCardTransactions != null && selectedCardTransactions.size() > 0)? selectedCardTransactions[0].id : null;
                    PSA_Card_Transaction_Item__c[] transItems = generateItemizedTransactions(cardTransId,
                                                                                             itemizedBillTrans,
                                                                                             itemizedNoBillTrans,
                                                                                             itemizedPersonalTransactions,
                                                                                             true);

                }
            }

            // generate expense!
            pse__Expense__c[] expensesToCreate = createExpenses(userExpenseReport,
                                                                billableTransactions,
                                                                nonBillableTransactions);

            // maintain this so we can do our 2 phased expense update
            // to get around validation rule
            //
            Map<Id, Id[]> cardTransIdToExpenseId = new Map<Id, Id[]>();

            if (expensesToCreate != null && expensesToCreate.size() > 0)
            {
                // * we need to update the itemized expense items to use the one selected card transaction
                //   the itemized lines are created from

                if (isItemizing)
                {
                    if (selectedCardTransactions != null && selectedCardTransactions.size() > 0 && selectedCardTransactions[0].id != null)
                    {
                        for (pse__Expense__c exp : expensesToCreate)
                        {
                            exp.PSA_Card_Transaction__c = exp.PSA_Card_Transaction__c != null ? exp.PSA_Card_Transaction__c : selectedCardTransactions[0].id;
                        }
                    }

                }

                insert expensesToCreate;

                // build map of expense-id to card-transaction-ids
                Map<Id, Id> expenseIdToCardTransId = new Map<Id, Id>();
                for (pse__Expense__c exp : expensesToCreate)
                {
                    //cardTransIdToExpenseId.put(pctw.cardTransaction.id, pctw.expense.id);
                    Id[] expIds = cardTransIdToExpenseId.get(exp.PSA_Card_Transaction__c);
                    expIds = expIds != null ? expIds : new Id[]{};

                    expIds.add(exp.id);
                    cardTransIdToExpenseId.put(exp.PSA_Card_Transaction__c, expIds);
                }


system.debug('\n ************ \n expensesToCreate > ' + expensesToCreate);

                // *** -- migrate attachments, if any, from card trans to the new expense items...

//                // + merge all card trans
//                PSACardTransactionWrapper[] allTransWrappers = new PSACardTransactionWrapper[]{};
//                allTransWrappers.addAll(billableTransactions);
//                allTransWrappers.addAll(nonBillableTransactions);

//                // + get a map of cardTransId to expenseId
//                //Map<Id, Id> cardTransIdToExpenseId = new Map<Id, Id>();
//                for (PSACardTransactionWrapper pctw : allTransWrappers)
//                {
//                    cardTransIdToExpenseId.put(pctw.cardTransaction.id, pctw.expense.id);
//                }

//system.debug('\n *************** \n cardTransIdToExpenseId > ' + cardTransIdToExpenseId);

                // expense attachments to create
                Attachment[] expAttachmentsToCreate = new Attachment[]{};
                // card attachments to remove
                Attachment[] cardAttachmentsToRemove = new Attachment[]{};

                for (Attachment cardTransToClone : [
                    select id, name, body, parentId
                    from attachment
                    where parentid in :cardTransIdToExpenseId.keySet() ])
                {
                    // lookup the expense id mapped to the card transaction
                    Id[] expenseParentIds = cardTransIdToExpenseId.get(cardTransToClone.parentid);
                    //system.assert(expenseParentId != null);
                    if (expenseParentIds != null && expenseParentIds.size() > 0)
                    {
                        for (Id expenseParentId : expenseParentIds)
                        {
                            expAttachmentsToCreate.add(
                                new Attachment(
                                    parentid = expenseParentId,
                                    name = cardTransToClone.name,
                                    body = cardTransToClone.body
                                )
                            );
                        }
                        cardAttachmentsToRemove.add(cardTransToClone);

                    }

                }
                // create new expense attachments
                if (expAttachmentsToCreate != null && expAttachmentsToCreate.size() > 0)
                {
                     insert expAttachmentsToCreate;
                }
                // remove old card trans
                if (cardAttachmentsToRemove != null && cardAttachmentsToRemove.size() > 0)
                {
                    delete cardAttachmentsToRemove;
                }
            }

            if (selectedCardTransactions != null && selectedCardTransactions.size() > 0)
            {
                // update the selected card transactions
                update selectedCardTransactions;

                // *************************************************
                // now we need to update the cards we associated with an expense report as being assigned
                // and handle 'personal' itemizations...
                PSA_Card_Transaction__c[] assignedTrans = new PSA_Card_Transaction__c[]{};
                if (isItemizing)
                {
                    // when itemizing a transaction, we will only have one selected card transaction
                    // but may have many billable / non-billable
                    if (selectedCardTransactions != null && selectedCardTransactions.size() > 0)
                    {
                        selectedCardTransactions[0].PSA_Status__c = 'Assigned';
                        selectedCardTransactions[0].PSA_Charge_Type__c = (personalTransactions != null && personalTransactions.size() > 0) ? 'Itemized' : 'Company';

                        assignedTrans.add(selectedCardTransactions[0]);
                    }
                }
                else
                {
                    // mark all transaction we converted into expenses
                    if (billableTransactions != null && billableTransactions.size() > 0) {
                        for (PSACardTransactionWrapper c : billableTransactions) {
                            if(c.cardTransaction.id != null) {
                                c.cardTransaction.PSA_Status__c = 'Assigned';
                                assignedTrans.add(c.cardTransaction);
                            }
                        }
                    }
                    if (nonBillableTransactions != null && nonBillableTransactions.size() > 0) {
                        for (PSACardTransactionWrapper c : nonBillableTransactions) {
                            if (c.cardTransaction.id != null) {
                                c.cardTransaction.PSA_Status__c = 'Assigned';
                                assignedTrans.add(c.cardTransaction);
                            }
                        }
                    }
                }

                if (assignedTrans != null && assignedTrans.size() > 0) {
                    update assignedTrans;
                }

                // need to collect the expense report ids of just created expenses.....
                for (pse__Expense__c exp : expensesToCreate)
                {
                    updatedExpenseReportIds.add(exp.pse__Expense_Report__c);
                }
            }

            // ------- reset !!!

            // now we need to remove the itemized transactions from the list
            hasItemizedCardTransaction = false;

            if (isItemizing)
            {
                // need to indicate that this transaction has been saved and should
                // be removed from the ui list (without refreshing the entire list)
                isItemizedTransactionSaved = true;
                // ????
                /// transactionIdSaved = selectedCardTransactions[0].id;

                //Set<Id> cardTransIds = cardTransIdToExpenseId.keySet();

                for (PSACardTransactionWrapper cw : cardTransactionWrappers)
                {
                    if (cw.selected && cw.cardTransaction.id == itemizingCardTransId)
                    {
                        cw.selected = false;
                        cw.isStale = true;

                        // let the page know it can remove this from the view....
                        transactionIdSaved = itemizingCardTransId;
                        break;
                    }
                }
            }
            else
            {
//***************
                // ok....mark as unselected and stale...collect the ones to remove from the page
                String[] transactionIdsToClearFromPage = new String[]{};

                // need to collect the card transaction items we just added ...
                // then we will remove from the list....
                for (PSACardTransactionWrapper cw : cardTransactionWrappers)
                {
                    if (cw.selected || cw.isStale)
                    {
                        cw.selected = false;
                        cw.isStale = true;

                        if (cw.cardTransaction.id != null) {
                            transactionIdsToClearFromPage.add(cw.cardTransaction.id);
                        }
                    }
                }

                // now need to add to the page??
                //transactionIdsToClearFromPage


                savedTransIds = String.join(transactionIdsToClearFromPage, ',');


                // not itemizing...then saving...reload all after save!
                //loadUserCardTransactions();
            }


            // load expense reports just updated (if any).....
            if (updatedExpenseReportIds != null && updatedExpenseReportIds.size() > 0)
            {
                recentlySavedExpenseReports = [select id, name
                                                 from pse__Expense_Report__c
                                                where id in :updatedExpenseReportIds];
            }

            //system.debug('\n --------------------------- \n recentlySavedExpenseReports ' + recentlySavedExpenseReports);

            // notify of success!
            addPageSuccessMessage('SUCCESS. Card transaction(s) have been updated.');

        }
        catch(Exception e)
        {
            if (savePoint != null)
            {
                Database.rollback(savePoint);
            }

            //String fullerr = e.getCause() + ' \n ' + e.getMessage() + ' \n ' + e.getLineNumber() + ' \n ' + e.getStackTraceString();
            //addPageErrorMessage(fullerr);

            String fullerr =  e.getMessage();
            addPageErrorMessage(fullerr);
        }
    }



    /**
     * Initialize Card Transaction Items from itemized transactions
     */
    private PSA_Card_Transaction_Item__c initializeCardTransactionItem(Id masterPsaCardTransactionId, PSA_Card_Transaction__c itemizedCardTrans)
    {
        PSA_Card_Transaction_Item__c transItem = new PSA_Card_Transaction_Item__c();

        transItem.PSA_Card_Transaction__c            = masterPsaCardTransactionId;
        transItem.CurrencyIsoCode                    = itemizedCardTrans.CurrencyIsoCode;
        transItem.PSA_Charge_Type__c                 = itemizedCardTrans.PSA_Charge_Type__c;

        transItem.PSA_Amount_in_Original_Currency__c = itemizedCardTrans.PSA_Amount_in_Original_Currency__c;

        transItem.GW_Card_Reimbursement_Amount__c    = itemizedCardTrans.PSA_Amount_in_Billing_Currency__c;
        transItem.PSA_Expense_Report__c              = itemizedCardTrans.PSA_Expense_Report__c;
        return transItem;
    }


    public class psaExpCardTransException extends Exception {}

    /**
     *  Create expense items, from card transactions, for the specific reports
     *
     */
    public pse__Expense__c[] createExpenses(pse__Expense_Report__c expenseReport,
                                            PSACardTransactionWrapper[] billableCardTransactions,
                                            PSACardTransactionWrapper[] nonBillableCardTransactions)
    {
        if (expenseReport == null)
        {
            throw new psaExpCardTransException('Error: Attempt to create an expense without specifying a valid expense report');
        }

        // create expense items from card transactions
        pse__Expense__c[] expenseItems = new pse__Expense__c[]{};
        if (billableCardTransactions != null && billableCardTransactions.size() > 0)
        {
            for (PSACardTransactionWrapper cardTransaction : billableCardTransactions)
            {
                if (!cardTransaction.isStale)
                {
                    //1.  Billable Amount = Transaction.Amount in Original Currency
                    //2.  Non-Billable Incurred Amount = 0
                    //3.  Billable = True
                    pse__Expense__c expItem = initializeExpenseItemFrom(expenseReport, cardTransaction);
                    expItem.pse__Billable__c = true;
                    expItem.pse__Non_Billable_Incurred_Amount__c = 0;

                    expenseItems.add(expItem);
                }
            }
        }

        if (nonBillableCardTransactions != null && nonBillableCardTransactions.size() >0)
        {
            for (PSACardTransactionWrapper cardTransaction : nonBillableCardTransactions)
            {
                if (!cardTransaction.isStale)
                {
                    //1.  Billable Amount = 0
                    //2.  Non-Billable Incurred Amount = Transaction.Amount in Original Currency
                    //3.  Billable = False
                    pse__Expense__c expItem = initializeExpenseItemFrom(expenseReport, cardTransaction);
                    expItem.pse__Billable__c = false;
                    expItem.pse__Non_Billable_Incurred_Amount__c = 0; //cardTransaction.PSA_Amount_in_Original_Currency__c;

                    expenseItems.add(expItem);
                }
            }
        }


        return expenseItems;
    }

    /**
     * Initializes an expense object from a card transaction wrapper
     * and card transciton.
     * * contains the logic for the mapping of psa-card-transaction to expense
     */
    private pse__Expense__c initializeExpenseItemFrom(pse__Expense_Report__c expReport,
                                                      PSACardTransactionWrapper cardTransactionWrapper)
    {
        PSA_Card_Transaction__c cardTransaction = cardTransactionWrapper.cardTransaction;
        PSA_Card_Transaction_Item__c cardTransItem = cardTransactionWrapper.cardTransactionItem;

        pse__Expense__c expenseItem = cardTransactionWrapper.expense; // use the expense from the card transaction, allows for adding more expense related fields


        String expDescription = cardTransaction.PSA_Merchant_Name__c + ' ' +
                                cardTransaction.PSA_Merchant_State_Province__c  + ', ' +
                                cardTransaction.PSA_Merchant_Country_Code__c;

        expDescription = expDescription.length() > 255 ? expDescription.substring(0, 250) : expDescription;

        expenseItem.CurrencyIsoCode                 = cardTransaction.CurrencyIsoCode;

        Double amt = cardTransaction.PSA_Amount_in_Original_Currency__c;   // default
        Double gwCardReimbAmt = cardTransaction.PSA_Amount_in_Billing_Currency__c; // default

        // useRemainingAmtForExpense - indicates we need to use the remaining transaction amount as expense amount
        //                           - and pull out the gwCardReimbAmount from the item....
        if (cardTransactionWrapper.useRemainingAmtForExpense &&
            amt != null &&
            cardTransaction.PSA_Remaining_Transaction_Amount__c != null &&
            cardTransaction.PSA_Remaining_Transaction_Amount__c <= amt)
        {

            amt = cardTransaction.PSA_Remaining_Transaction_Amount__c;
            amt = (amt < 0) ? 0 : amt;

            if (cardTransItem != null)
            {
                gwCardReimbAmt = cardTransItem.GW_Card_Reimbursement_Amount__c;
            }
        }


        expenseItem.pse__Amount__c                  = amt;
        //expenseItem.pse__Amount__c                  = cardTransaction.PSA_Amount_in_Original_Currency__c;

        expenseItem.GW_Card_Reimbursement_Amount__c = gwCardReimbAmt;
        //expenseItem.GW_Card_Reimbursement_Amount__c = cardTransaction.PSA_Amount_in_Billing_Currency__c;

        expenseItem.pse__Type__c                    = cardTransaction.PSA_Expense_Type__c;
        expenseItem.pse__Description__c             = expDescription;
        expenseItem.pse__Expense_Date__c            = cardTransaction.PSA_Transaction_Date__c;
        expenseItem.pse__Expense_Report__c          = cardTransaction.PSA_Expense_Report__c; // SET FROM THE CARD TRANSACTION
        expenseItem.pse__resource__c                = expReport.pse__Resource__c;
        expenseItem.PSA_Card_Transaction__c         = cardTransaction.id;
        expenseItem.PSA_GW_Card__c                  = true;
        expenseItem.pse__non_reimbursible__c        = true;

        // map card transaction item to expense..
        if (cardTransactionWrapper.cardTransactionItem != null && cardTransactionWrapper.cardTransactionItem.Id != null)
        {
            expenseItem.PSA_Card_Transaction_Item__c = cardTransactionWrapper.cardTransactionItem.Id;
        }

        if (cardTransaction.PSA_FX__c != null)
        {
            expenseItem.pse__Exchange_Rate_Resource_Defined__c = cardTransaction.PSA_FX__c;
        }

        //expenseItem.pse__Billing_Amount__c  = cardTransaction.PSA_Amount_in_Original_Currency__c;
        return expenseItem;
    }


    // ----------------- WRAPPER CLASSESES

    // ----------------------------------------------------
    // Wrapper for our card transactions were going to display
    // ----------------------------------------------------
    public class PSACardTransactionWrapper
    {
        public PSA_Card_Transaction__c cardTransaction {get; set;}

        public PSA_Card_Transaction_Item__c cardTransactionItem {get; set;}


        // returns the card transaction date formatted as yyyy-MM-dd
        public String transactionDateFormatted {get; set;}


        //public String transactionDateFormatted {get {
        //    if (transactionDateFormatted == null &&
        //        cardTransaction != null &&
        //        cardTransaction.PSA_Transaction_Date__c != null) {

        //        Date transDate = cardTransaction.PSA_Transaction_Date__c;
        //        transactionDateFormatted = DateTime.newInstance(transDate.year(),transDate.month(),transDate.day()).format('yyyy-MM-dd');

        //    }
        //    return transactionDateFormatted;
        //} private set;}


        public boolean selected {get; set;}

        // will be true when the transaction is itemized, but only removed from the ui
        // and not the underlying page list
        public boolean isStale {get; set;}

        public boolean billable {get; set;}
        public boolean previouslyEntered {get; set;}
        public boolean personal {get; set;}


        public boolean invalidTransaction {get; set;}
        public boolean hasAttachments {get; set;}
        public Integer counter {get; set;}

        // when true...stores the remaining amount to the expense amount
        public boolean useRemainingAmtForExpense {get; set;}

        // will be stored as the new card transaction expense
        public pse__Expense__c expense {get; set;}


        public PSACardTransactionWrapper(PSA_Card_Transaction__c cardTrans)
        {
            this.billable = true;
            this.previouslyEntered = false;
            this.personal = false;
            this.selected = false;
            this.invalidTransaction = false;
            this.cardTransaction = cardTrans;
            this.useRemainingAmtForExpense = false;
            this.cardTransactionItem = null;
            this.isStale = false;

            this.expense = new pse__Expense__c(
                PSA_Incurred_Country__c = cardTrans.PSA_Incurred_Country__c,
                PSA_Incurred_State_Province__c = cardTrans.PSA_Incurred_State_Province__c
            );

            this.hasAttachments = (cardTrans.Attachments != null && cardTrans.attachments.size()> 0);

            //this.receiptType = 'No Receipt';
            //this.attendees = '';


            if (cardTransaction != null &&
                cardTransaction.PSA_Transaction_Date__c != null)
            {
                Date dt = cardTransaction.PSA_Transaction_Date__c;

                //this.cardTransDt = DateTime.newInstance(dt.year(),transDate.month(),transDate.day()).format('yyyy-MM-dd');
                //this.transactionDateFormatted = dt.year() + '-' + dt.month() + '-' + dt.day();

                transactionDateFormatted = DateTime.newInstance(dt.year(),dt.month(),dt.day()).format('yyyy-MM-dd');
            }

            this.counter = 0;
        }



        // # Convenient method for cacluating gw card reimbursement amount for itemizations
        // #        GW Card Reimbursement Amount = (Amount in Billing Currency) * (Amount field from “Itemize Transactions - Multiple Expenses screen” / Transaction.Amount in Original Currency)
        // #
        // # itemAmount - Itemized amount field...
        public Decimal calculateGWCardReimburesementAmount(Decimal itemAmount)
        {
            // cw.calculateCardReimburesement(itemAmount)
            Decimal rslt = 0;


            Decimal totalAmountInOriginal = this.cardTransaction.PSA_Amount_in_Original_Currency__c;
            Decimal totalAmountInBilling  = this.cardTransaction.PSA_Amount_in_Billing_Currency__c != null ? this.cardTransaction.PSA_Amount_in_Billing_Currency__c : totalAmountInOriginal;

            //system.debug(' \n\n calculateGWCardReimburesementAmount ????? ' +
            //                '\n totalAmountInBilling:' + totalAmountInBilling +
            //                '\n itemAmount:' + itemAmount +
            //                '\n totalAmountInOriginal' + totalAmountInOriginal +
            //                '\n amt in bill curr? ' + totalAmountInBilling * (itemAmount / totalAmountInOriginal) +
            //                '\n ------------------- \n');


            // calculate amount in billing currency
            if (totalAmountInOriginal != null && totalAmountInOriginal > 0 && totalAmountInOriginal >= itemAmount && totalAmountInBilling != null)
            {
                //GW Card Reimbursement Amount = Amount in Billing Currency * (Amount field from “Itemize Transactions - Multiple Expenses screen” / Transaction.Amount in Original Currency)
                rslt = totalAmountInBilling * (itemAmount / totalAmountInOriginal);
            }
            return rslt;
        }

    }


    // thrown on PSAItemizedTransactionWrapper error!
    public class PSAItemizedTransactionException extends Exception {}


    // ----------------------------------------------------
    // Wrapper for the card transaction to itemize
    // ----------------------------------------------------
    public class PSAItemizedTransactionWrapper
    {
        public PSA_Card_Transaction__c cardTransaction {get; set;}
        public PSACardTransactionWrapper[] itemizedTransactions {get; private set;} //


        public PSACardTransactionWrapper origWrapperToItemize {get; set;}

        public Decimal itemizedAmountTotals {get; set;}
        public Decimal itemizedAmountsRemaining {get; set;}

        //selectedTransactionWrapper

        //public PSAItemizedTransactionWrapper(PSA_Card_Transaction__c ct)
        public PSAItemizedTransactionWrapper(PSACardTransactionWrapper transToItemize)
        {
            this.origWrapperToItemize = transToItemize;

            this.cardTransaction = transToItemize.cardTransaction;
            //this.cardTransaction = ct;

            this.itemizedAmountTotals = 0;

            this.itemizedAmountsRemaining =  transToItemize.cardTransaction.PSA_Remaining_Transaction_Amount__c;

            // system.debug('\n **** \n origWrapperToItemize > ' + origWrapperToItemize);

            // initialize and pre-populate our itemized transactions (we clone the original transaction and remove the ids)...
            PSA_Card_Transaction__c itemtrans_01 = (cardTransaction != null) ? cardTransaction.clone() : new PSA_Card_Transaction__c();
            itemtrans_01.id = null;
            itemtrans_01.PSA_Amount_in_Original_Currency__c = itemizedAmountsRemaining;

            //PSACardTransactionWrapper itemizedTransWrapper_01 = new PSACardTransactionWrapper(itemtrans_01);

            PSA_Card_Transaction__c itemtrans_02 = (cardTransaction != null) ? cardTransaction.clone() : new PSA_Card_Transaction__c();
            itemtrans_02.id = null;
            itemtrans_02.PSA_Amount_in_Original_Currency__c = 0;

            //PSACardTransactionWrapper itemizedTransWrapper_02 = new PSACardTransactionWrapper(itemtrans_02);

            itemizedTransactions = new PSACardTransactionWrapper[]{
                buildCardTransWrapper(itemtrans_01),
                buildCardTransWrapper(itemtrans_02)
            };
            itemizedTransactions[1].counter = 1;

            this.sumItemizedAmounts();

        }

        // ------------------------------------------------------------------------------------
        // - convenient method to build card transaction wrappers, cloning the current selected expense data!
        private PSACardTransactionWrapper buildCardTransWrapper(PSA_Card_Transaction__c cardTrans)
        {
            PSACardTransactionWrapper itemizedTransWrapper_Rslt = new PSACardTransactionWrapper(cardTrans);

            // need to pre-populate expense from current ui transaction......
            if (origWrapperToItemize != null && origWrapperToItemize.expense != null)
            {
                pse__Expense__c transexp_01 = origWrapperToItemize.expense.clone();
                transexp_01.id = null;
                itemizedTransWrapper_Rslt.expense = transexp_01;
            }

            return itemizedTransWrapper_Rslt;
        }

        // increment the counter (used in UI checkbox logic for billable/personal marked expenses)
        public void addNewTransaction(PSACardTransactionWrapper npst)
        {
            if (npst != null) {
                npst.counter = itemizedTransactions.size();
            }
            itemizedTransactions.add(npst);
            sumItemizedAmounts();
        }

        // calculate the itemized totals
        public void sumItemizedAmounts()
        {
            Decimal sumItemized = 0.0;
            for (PSACardTransactionWrapper pctw : itemizedTransactions)
            {
                sumItemized += pctw.cardTransaction.PSA_Amount_in_Original_Currency__c;
            }
            this.itemizedAmountTotals = sumItemized;
        }

        // validates the itemized transaction wrapper.
        // ensures the itemized amounts are equal to the underlying card transaction
        // throws PSAItemizedTransactionWrapper on error
        // return boolean on success
        public boolean isValid()
        {
            Boolean valid = true;
            String[] errMsgs = new String[]{};

            errMsgs.add('The page encountered errors with your request:');

            sumItemizedAmounts();  // ensure we have upto date totals


            // verify the itemized totals match the underlying card transaction
            if (this.itemizedAmountTotals != this.cardTransaction.PSA_Remaining_Transaction_Amount__c)
            {
                valid = false;
                errMsgs.add('The itemized amounts should equal the original card transaction amount.  [' + itemizedAmountTotals + '] <> [' + cardTransaction.PSA_Remaining_Transaction_Amount__c + ']');
            }

            // verify each row has either a billable or personal checked (but not both!)
            for (PSACardTransactionWrapper pctw : itemizedTransactions)
            {
                // when billable and personal are checked...thats an error
                if (pctw.billable == true && pctw.personal == true)
                {
                    valid = false;
                    errMsgs.add('An expense can not be checked billable and personal.  Please remove the duplicate and submit again.');
                    break;
                }

                // when no amounts are specified....thats an error..
                if (pctw.cardTransaction.PSA_Amount_in_Original_Currency__c == null || pctw.cardTransaction.PSA_Amount_in_Original_Currency__c <= 0.0)
                {
                    valid = false;
                    errMsgs.add('Please specify amounts for all itemized transactions, or delete the row and submit again.');
                    break;
                }


            }

            if (!valid && errMsgs.size() > 0)
            {
                String errmsg = String.join(errMsgs, '<br/>');
                throw new PSAItemizedTransactionException(errmsg);
            }

            return valid;
        }

    }

    // ------------------------------------------------------------------------
    // # Retrieves expenses for matching to card transactions
    // # jsonFilterFields : JSON serialized string of mapped (Map<String, Object) expense fields to filter:
    //      - (example from Javascript:)
    //          var filterFields = {
    //              resourceId: ''
    //                  status: 'All',
    //       expenseReportName: 'Expense Report Name',
    //            expenseNotes: 'Expense Notes that contain..',
    //                fromDate: '2016-01-01',
    //                  toDate: '2017-01-01'
    //          }
    // ------------------------------------------------------------------------
    @RemoteAction global static Map<String, Object> lookupExpenses(String jsonFilterFields)
    {
        Map<String, Object> result = new Map<String, Object>();

        Map<String, Object> incomingJsonFilterFields = null;
        try {
            incomingJsonFilterFields = (Map<String, Object>)JSON.deserializeUntyped(jsonFilterFields);
        } catch (Exception je) {
            //system.debug('JSON_PARSER_ERROR');
            //system.debug(je);
            return makeError(je.getMessage());
        }

        try
        {
            String userExpenseReportId = null;
            if (incomingJsonFilterFields.containsKey('userExpenseReportId')) {
                userExpenseReportId = String.valueOf(incomingJsonFilterFields.get('userExpenseReportId'));
            }

            // optionally like expense report name!
            String expenseReportName = null;
            if (incomingJsonFilterFields.containsKey('expenseReportName') && userExpenseReportId == null) {
                expenseReportName = String.valueOf(incomingJsonFilterFields.get('expenseReportName'));
            }

            String expenseNotes = null;
            if (incomingJsonFilterFields.containsKey('expenseNotes') && userExpenseReportId == null) {
                expenseNotes = String.valueOf(incomingJsonFilterFields.get('expenseNotes'));
            }

            // parse json input.....
            //
            // required resource id
            String resourceId = null;
            if (incomingJsonFilterFields.containsKey('resourceId')) {
                resourceId = String.valueOf(incomingJsonFilterFields.get('resourceId'));
            }
            if (resourceId == null)
            {
                return makeError(' missing required resource id ');
            }

            // optional status
            String status = null;
            if (incomingJsonFilterFields.containsKey('status')) {
                status = String.valueOf(incomingJsonFilterFields.get('status'));
            }
            // optional from date expense date
            String fromDateParm = null;
            if (incomingJsonFilterFields.containsKey('fromExpDate')) {
                fromDateParm = String.valueOf(incomingJsonFilterFields.get('fromExpDate'));
                fromDateParm = (fromDateParm == 'null') ? null : fromDateParm;
            }
            // optional to expense date
            String toDateParm = null;
            if (incomingJsonFilterFields.containsKey('toExpDate')) {
                toDateParm = String.valueOf(incomingJsonFilterFields.get('toExpDate'));
                toDateParm = (toDateParm == 'null') ? null : toDateParm;
            }

            // ---- offset - defaults to 0
            Integer inputOffset = 0;
            if (incomingJsonFilterFields.containsKey('offset')) {
                inputOffset = Integer.valueOf(incomingJsonFilterFields.get('offset'));
            }

            // ---- limit - defaults to 100 (maybe can be increased to 2000??)
            Integer inputLimit = 100;
            if (incomingJsonFilterFields.containsKey('limit')) {
                inputLimit = Integer.valueOf(incomingJsonFilterFields.get('limit'));
            }


            // Expense fields we will retrieve
            //
            // ...
            String[] expenseFields = new String[]{
                'Id',
                'Name',
                'GW_Card_Reimbursement_Amount__c',
                'PSA_GW_Card__c',
                'PSA_Card_Transaction__c',
                'pse__Expense_Report__c',
                'pse__Notes__c',
                'pse__Expense_Report__r.Name',
                'pse__Amount__c',
                'CurrencyIsoCode',
                'pse__Description__c',
                'pse__Expense_Date__c',
                'pse__Resource__c',
                'pse__Type__c',
                'pse__Status__c',
                'OwnerId'
            };

            // build our dynamic soql...
            String soql  = ' SELECT ' + String.join(expenseFields, ',') + ' ';
                   soql += '   FROM pse__Expense__c ';
                   soql += '  WHERE pse__Resource__c = \'' + resourceId + '\' ';
                   soql += '    AND PSA_Card_Transaction__c = \'\' ';

            if (String.isNotEmpty(userExpenseReportId))
            {
                soql += ' AND pse__Expense_Report__c = \'' + userExpenseReportId + '\' ' ;
            }

            // conditionally add status filter
            if (String.isNotEmpty(status) && (status == 'Draft' || status == 'Rejected' || status == 'Approved' || status == 'Submitted') )
            {
                soql += ' AND pse__Status__c = \'' + status + '\' ';
            }
            else
            {
                soql += ' AND pse__Status__c in(\'Draft\', \'Rejected\')';
            }

            // conditionally from expense date filter
            if (String.isNotEmpty(fromDateParm))
            {
                soql += ' AND pse__Expense_Date__c >= ' + fromDateParm + ' ';
            }

            // conditionally add to expense date filter
            if (String.isNotEmpty(toDateParm))
            {
                soql += ' AND pse__Expense_Date__c <= ' + toDateParm + ' ';
            }

            // by expense report name.....
            if (String.isNotEmpty(expenseReportName))
            {
                soql += ' AND pse__Expense_Report__r.Name like \'%' + expenseReportName + '%\' ';
            }

            // by expense notes....
            if (String.isNotEmpty(expenseNotes))
            {
                soql += ' AND pse__Notes__c like \'%' + expenseNotes + '%\' ';
            }

            // set the limit and offset....if specifi
            soql += ' LIMIT ' + inputLimit + ' ' ;
            //if (offset > 0) {
                soql += ' OFFSET ' + inputOffset + ' ';
            //}

            //system.debug(soql);

            pse__Expense__c[] expenses = Database.query(soql);

            result.put('records', expenses);
            result.put('size', expenses.size());

            return result;
        }
        catch(Exception e)
        {
            return makeError(e.getMessage());
        }

    }

    // convenient method to make an error for returning to the ui!
    private static Map<String, Object> makeError(String errMsg)
    {
        return new Map<String, Object>{
            'error' => true,
            'errorMessage' => errMsg
        };
    }

    // ----
    // returns picklist options for selecting state
    public SelectOption[] incurredStateProvOptions {get{
        if (incurredStateProvOptions == null)
        {
            incurredStateProvOptions = new SelectOption[]{};
            incurredStateProvOptions.add(new SelectOption('', '-- NONE --'));
            for (pw_cc__State__c stateOrProv : [
                select Id, Name, pw_cc__Country__r.name
                from pw_cc__State__c
                where pw_cc__Country__r.name in ('United States', 'Canada')
                order by pw_cc__Country__r.name desc, name
            ])
            {
                incurredStateProvOptions.add(new SelectOption(stateOrProv.id, stateOrProv.name));
            }
        }
        return incurredStateProvOptions;
    } private set;}

}