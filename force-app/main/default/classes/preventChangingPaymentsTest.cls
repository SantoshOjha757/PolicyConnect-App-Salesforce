@isTest
private with sharing class preventChangingPaymentsTest {

    @testSetup
    static void testData(){

        // creating policyholder
        Account policyholder = new Account();
        policyholder.FirstName = 'Test';
        policyholder.LastName = 'Policyholder';
        policyholder.Aadhaar_Number__c  = '1010 2020 3030';
        policyholder.PAN_Number__c = 'ACSPO0598K';
        insert policyholder;

        // creating agent
        Contact agentRec = new Contact();
        agentRec.FirstName = 'Test';
        agentRec.LastName = 'Agent';
        insert agentRec;

        // standard pricebook
        List<Pricebook2> standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE IsStandard = true LIMIT 1];

        // creating policy category (custom pricebook)
        Pricebook2 policyCategory = new Pricebook2();
        policyCategory.Name = 'Test Policy Plan-10Y-Yearly';
        policyCategory.IsActive = true;
        insert policyCategory;
        
        // creating policy plan
        Product2 policy = new Product2();
        policy.Name = 'Test Product';
        policy.IsActive = true;
        policy.ProductCode = 'tp_100';
        policy.Policy_Term_Range__c = 10;
        policy.Premium_Payment_Term__c = 10;
        policy.Premium_Payment_Type__c = 'Yearly';
        policy.Sum_Assured__c = 500000;
        policy.Category__c = 'Term Plan';
        insert policy;

        // creating standard pricebookEntry (required)
        PricebookEntry standardPricebookEntry = new PricebookEntry();
        standardPricebookEntry.Product2Id = policy.Id;
        standardPricebookEntry.Pricebook2Id = standardPricebook[0].Id;
        standardPricebookEntry.UnitPrice = 50000;
        standardPricebookEntry.IsActive = true;
        insert standardPricebookEntry;

        PricebookEntry pricebookEntry = new PricebookEntry();
        pricebookEntry.Product2Id = policy.Id;
        pricebookEntry.Pricebook2Id = policyCategory.Id;
        pricebookEntry.UnitPrice = 50000;
        pricebookEntry.UseStandardPrice = true;
        insert pricebookEntry;

        // creating policy purchase
        Order policyPurchase = new Order();
        policyPurchase.policy_holder__c = policyholder.Id;
        policyPurchase.Agent__c = agentRec.Id;
        insert policyPurchase;

        // creating order policy plan
        OrderItem orderProduct = new OrderItem();
        orderProduct.Product2Id = policy.Id;
        orderProduct.OrderId = policyPurchase.Id;
        orderProduct.Quantity = 10;
        orderProduct.UnitPrice = 50000;
        insert orderProduct;

        policyPurchase.Status = 'Activated';
        update policyPurchase;

        // creating premium payment
        Premium_Payment__c payment = new Premium_Payment__c();
        payment.Policy_Purchase__c = policyPurchase.Id;
        payment.Policyholder__c = policyholder.Id;
        payment.Agent__c = agentRec.Id;
        payment.Payment_Mode__c = 'Cash';
        payment.Payment_Date__c = Date.today();
        insert payment;

        payment.Status__c = 'Processed';
        update payment;
    }

    @isTest
    static void testUpdatePaymentByAgents() {

        Test.startTest();
        List<Profile> userProfileList = [SELECT Id, Name FROM Profile WHERE Name IN ('LIC Agents', 'LIC ADO')];
        List<UserRole> userRoleList = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN ('LIC_Agents', 'LIC_ADO')];

        // calling data factory class
        User agentUser = TestUserDataFactory.createTestUsers('Test', 'Agent', 'test_agent@email.com', 'test_agent', userProfileList[0].Id, userRoleList[0].Id);
        
        System.runAs(agentUser){
            Premium_Payment__c existingPayment = [SELECT Id, Status__c FROM Premium_Payment__c WHERE Status__c = 'Processed' LIMIT 1];
            try{
                existingPayment.Status__c = 'Pending';
                update existingPayment;
                System.assert(false, 'payment should be updated');
            } catch(exception e){
                System.assert(true, e.getMessage());
            }           
        }
        Test.stopTest();
    }

    // @isTest
    // static void testUpdatePaymentByADO() {

    // }

    // @isTest
    // static void testDeletePaymentByAgent() {

    // }

    // @isTest
    // static void testDeletePaymentByADO() {

    // }
}