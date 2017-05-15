@isTest
public class MP_TestUtility {
    public static ccrz__E_AccountGroup__c createAccountGroup (){
        ccrz__E_AccountGroup__c ag = new ccrz__E_AccountGroup__c();
        ag.Name = 'Account Group';
        ag.ccrz__AccountGroupID__c = 'accountgroup';
        ag.ccrz__PriceListSelectionMethod__c = 'Best Price';
        return ag;
    }
    public static Account createAccount(String name, Id accountGroup){
        Account accRec = new Account();
        accRec.Name = name;
        accRec.Buying_Entity__c = 'Yes';
        accRec.CurrencyIsoCode = 'USD';
        accRec.Industry = 'Agency';
        accRec.Type = 'Potential Partner';
        accRec.Record_Status__c = 'Active';
        accRec.BillingStreet = '123 Test Street';
        accRec.BillingCity = 'Foster City';
        accRec.BillingState = 'CA';
        accRec.BillingPostalCode = '12345';
        accRec.BillingCountry = 'USA';
        accRec.Alliance_Type__c = 'PartnerConnect - Consulting';
        accRec.ccrz__E_AccountGroup__c = accountGroup;
        return accRec;
    }
    public static Contact createContact(Id accId, String firstName, String lastName){
        Contact contRec = new Contact();
        contRec.FirstName = firstName;
        contRec.LastName = lastName;
        contRec.AccountId = accId;
        contRec.Category__c = 'Billing';
        contRec.Phone = '(510) 123 4567';
        contRec.HomePhone = '(510) 123 4567';
        contRec.MobilePhone = '(510) 123 4567';
        contRec.CurrencyIsoCode = 'USD';
        contRec.MailingStreet = '123 Test Street';
        contRec.MailingCity = 'Foster City';
        contRec.MailingState = 'CA';
        contRec.MailingPostalCode = '12345';
        contRec.MailingCountry = 'USA';
        return contRec;
    }
    public static User createAdminUser(Integer num, Id profileId, Id roleId){
        string randomName = string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','');
        User userRec = new User();
        userRec.FirstName = 'Test';
        userRec.LastName = 'Admin';
        userRec.Email = userRec.FirstName + userRec.LastName + '@email.com';
        userRec.Username = userRec.Email+randomName+num;
        userRec.Alias = 'alias'+num;
        userRec.LanguageLocaleKey = 'en_US';
        userRec.EmailEncodingKey='UTF-8';
        userRec.TimeZoneSidKey='America/Los_Angeles';
        userRec.LocaleSidKey = 'en_US';
        userRec.ProfileId = profileId;
        userRec.UserRoleId = roleId;
        userRec.IsActive = true;
        return userRec;
    }
    public static User createCommunityUser(Contact contRec, Integer num, Id profileId){
        string randomName = string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','');
        User userRec = new User();
        userRec.ContactId = contRec.Id;
        userRec.FirstName = contRec.FirstName;
        userRec.LastName = contRec.LastName;
        userRec.Email = userRec.FirstName + userRec.LastName + '@email.com';
        userRec.Username = userRec.Email+randomName+num;
        userRec.Alias = 'alias'+num;
        userRec.LanguageLocaleKey = 'en_US';
        userRec.EmailEncodingKey='UTF-8';
        userRec.TimeZoneSidKey='America/Los_Angeles';
        userRec.LocaleSidKey = 'en_US';
        userRec.ProfileId = profileId;
        userRec.IsActive = true;
        return userRec;
    }
    public static ccrz__E_Product__c createProduct(String name, String sku){
        ccrz__E_Product__c prodRec = new ccrz__E_Product__c();
        prodRec.Name = name;
        prodRec.ccrz__SKU__c = sku;
        prodRec.ccrz__Quantityperunit__c = 1;
        prodRec.ccrz__StartDate__c = date.today();
        prodRec.ccrz__EndDate__c = date.today() + 5;
        prodRec.ccrz__ProductStatus__c = 'Released';
        prodRec.MP_DownloadURL__c = 'www.google.com';
        return prodRec;
    }
    public static ccrz__E_Order__c createOrder(Id userId, Id accId){
        ccrz__E_Order__c ordRec = new ccrz__E_Order__c();
        ordRec.ccrz__OrderNumber__c = 123456789;
        ordRec.ccrz__EncryptedId__c = '03b12120-52c6-4aac-b15a-4f483be8bb26';
        ordRec.ccrz__OrderDate__c = date.today();
        ordRec.ccrz__OrderStatus__c = 'Ready to Download';
        ordRec.ccrz__User__c = userId;
        ordRec.ccrz__Account__c = accId;
        ordRec.ccrz__CurrencyISOCode__c = 'USD';
        return ordRec;
    }
    public static ccrz__E_OrderItem__c createOrderItem(Id orderId, Id productId){
        ccrz__E_OrderItem__c ordItemRec = new ccrz__E_OrderItem__c();
        ordItemRec.ccrz__Order__c = orderId;
        ordItemRec.ccrz__Product__c = productId;
        ordItemRec.ccrz__Price__c = 0;
        ordItemRec.ccrz__Quantity__c = 1;
        ordItemRec.ccrz__OrderLineType__c = 'Major';
        ordItemRec.ccrz__ProductType__c = 'Product';
        ordItemRec.ccrz__UnitOfMeasure__c = 'Each';
        ordItemRec.ccrz__ItemStatus__c = 'Available';
        ordItemRec.ccrz__SubAmount__c = 0;
        return ordItemRec;
    }
    public static ccrz__E_Menu__c createMenu(String displayName, String storeId){
        ccrz__E_Menu__c menuRec = new ccrz__E_Menu__c();
        menuRec.ccrz__DisplayName__c = displayName;
        menuRec.ccrz__StoreID__c = storeId;
        menuRec.ccrz__Enabled__c = true;
        menuRec.ccrz__StartDate__c = date.today() - 1;
        menuRec.ccrz__EndDate__c = date.today() + 1;
        menuRec.ccrz__LinkType__c = 'None';
        return menuRec;
    }
    public static ccrz__E_MenuItem__c createMenuItem(Id menuId, String displayName, String url){
        ccrz__E_MenuItem__c menuItemRec = new ccrz__E_MenuItem__c();
        menuItemRec.ccrz__DisplayName__c = displayName;
        menuItemRec.ccrz__Enabled__c = true;
        menuItemRec.ccrz__StartDate__c = date.today() - 1;
        menuItemRec.ccrz__EndDate__c = date.today() + 1;
        menuItemRec.ccrz__LinkType__c = 'URL';
        menuItemRec.ccrz__URL__c = url;
        menuItemRec.ccrz__Menu__c = menuId;
        return menuItemRec;
    }
}