@isTest
private with sharing class PremiumPaymentTriggerHandlerTest {

    @TestSetup
    static void testSetupRecords(){
        Account policyHolder = new Account(Name = 'Test Policyholder');
        insert policyHolder;

        Contact agent = new Contact(LastName = 'Test Agent');
        insert agent;

        Order policyPurchase = new Order(
            Name = 'Test Order',
            AccountId = policyHolder.Id,
            Agent__c = agent.Id,
            Total_Installments__c = 100,
            Status = 'Draft',
            EffectiveDate = Date.today()

        );
        insert policyPurchase;
    }

    @isTest
    static void testFieldValidation(){

        Test.startTest();
        Account policyholder = [SELECT Id, Name FROM Account WHERE Name = 'Test Policyholder'];
        Contact agent = [SELECT Id, LastName FROM Contact WHERE LastName = 'Test Agent'];
        Order policyPurchase = [SELECT Id, AccountId FROM Order WHERE AccountId =:policyholder.Id];

        Premium_Payment__c payment = new Premium_Payment__c(
            Payment_Date__c = Date.today()
        );
        try{
            insert payment;
            System.assert(false);
        }
        catch(Exception e){
            System.assert(true);
        }
        Test.stopTest();
    }

    @isTest
    static void testPaidInstallmentsUponInsert() {

        Test.startTest();
        Account policyholder = [SELECT Id, Name FROM Account WHERE Name = 'Test Policyholder'];
        Contact agent = [SELECT Id, LastName FROM Contact WHERE LastName = 'Test Agent'];
        Order policyPurchase = [SELECT Id, AccountId FROM Order WHERE AccountId =:policyholder.Id];

        Premium_Payment__c payment = new Premium_Payment__c(
            Policy_Purchase__c = policyPurchase.Id,
            Policyholder__c = policyholder.Id,
            Agent__c = agent.Id,
            Payment_Mode__c = 'Cash',
            Status__c = 'Processed',
            Verification_Status__c = 'Verified',
            Payment_Date__c = Date.today()
        );
        insert payment;
        Test.stopTest();

        List<Premium_Payment__c> insertedPayment = [SELECT Id, Paid_Installments__c, Last_Installment__c FROM Premium_Payment__c
                                                    WHERE Policy_Purchase__c =:policyPurchase.Id];

        for(Premium_Payment__c paymt : insertedPayment){
            System.assertEquals(1, paymt.Paid_Installments__c, 'Paid_Installment value should be 1');
        }
    }

    @isTest
    static void testPaidInstallmentsUponUpdate() {

        Test.startTest();
        Account policyholder = [SELECT Id, Name FROM Account WHERE Name = 'Test Policyholder'];
        Contact agent = [SELECT Id, LastName FROM Contact WHERE LastName = 'Test Agent'];
        Order policyPurchase = [SELECT Id, AccountId FROM Order WHERE AccountId =:policyholder.Id];

        Premium_Payment__c payment = new Premium_Payment__c(
            Policy_Purchase__c = policyPurchase.Id,
            Policyholder__c = policyholder.Id,
            Agent__c = agent.Id,
            Payment_Mode__c = 'Cheque',
            Status__c = 'Pending',
            Payment_Date__c = Date.today()
        );
        insert payment;

        Premium_Payment__c insertedPayment = [SELECT Id FROM Premium_Payment__c WHERE Id =: payment.Id AND Payment_Mode__c = 'Cheque' AND Status__c = 'Pending'];
        insertedPayment.Status__c = 'Processed';
        insertedPayment.Verification_Status__c = 'Verified';
        update insertedPayment;

        Test.stopTest();

        List<Premium_Payment__c> updatedPayment = [SELECT Id, Paid_Installments__c, Last_Installment__c FROM Premium_Payment__c
                                                    WHERE Policy_Purchase__c =:policyPurchase.Id];

        for(Premium_Payment__c paymt : updatedPayment){
            System.assertEquals(1, paymt.Paid_Installments__c, 'Paid_Installment value should be 1');
        }
    }

    @isTest
    static void testInstallmentCountEqualsTotalInstallmentsUponInsert() {

        Test.startTest();
        Account policyholder = [SELECT Id, Name FROM Account WHERE Name = 'Test Policyholder'];
        Contact agent = [SELECT Id, LastName FROM Contact WHERE LastName = 'Test Agent'];
        Order policyPurchase = [SELECT Id, AccountId FROM Order WHERE AccountId =:policyholder.Id];

        List<Premium_Payment__c> premiumPaymentList = new List<Premium_Payment__c>();

        for(Integer i=0; i<99; i++){
            premiumPaymentList.add(
                new Premium_Payment__c(
                    Policy_Purchase__c = policyPurchase.Id,
                    Policyholder__c = policyholder.Id,
                    Agent__c = agent.Id,
                    Payment_Mode__c = 'Cash',
                    Status__c = 'Processed',
                    Verification_Status__c = 'Verified',
                    Payment_Date__c = Date.today() + 30 * i
                )
            );
        }
        insert premiumPaymentList;
        Test.stopTest();

        List<Premium_Payment__c> insertedPayment = [SELECT Id, Paid_Installments__c, Last_Installment__c FROM Premium_Payment__c
                                                    WHERE Policy_Purchase__c =:policyPurchase.Id];

        System.assertEquals(100, insertedPayment.size());

        for(Integer i=99; i>= 0; i--){
            System.assertEquals(true, insertedPayment[i].Last_Installment__c, 'The Last Installment must be marked as true');    
            return;
        } 
    }

    @isTest
    static void testInstallmentCountEqualsTotalInstallmentsUponUpdate() {

        Test.startTest();
        Account policyholder = [SELECT Id, Name FROM Account WHERE Name = 'Test Policyholder'];
        Contact agent = [SELECT Id, LastName FROM Contact WHERE LastName = 'Test Agent'];
        Order policyPurchase = [SELECT Id, AccountId FROM Order WHERE AccountId =:policyholder.Id];

        List<Premium_Payment__c> premiumPaymentList = new List<Premium_Payment__c>();

        for(Integer i=0; i<98; i++){
            premiumPaymentList.add(
                new Premium_Payment__c(
                    Policy_Purchase__c = policyPurchase.Id,
                    Policyholder__c = policyholder.Id,
                    Agent__c = agent.Id,
                    Payment_Mode__c = 'cash',
                    Status__c = 'Processed',
                    Payment_Date__c = Date.today() + 30 * i
                )
            );
        }
        insert premiumPaymentList;

        Premium_Payment__c lastPayment = new Premium_Payment__c(
            Policy_Purchase__c = policyPurchase.Id,
            Policyholder__c = policyholder.Id,
            Agent__c = agent.Id,
            Payment_Mode__c = 'Cheque',
            Status__c = 'Pending',
            Payment_Date__c = Date.today().addDays(30)
        );
        insert lastPayment;

        lastPayment.Status__c = 'Processed';
        lastPayment.Verification_Status__c = 'Verified';
        update lastPayment;

        Test.stopTest();

        List<Premium_Payment__c> updatedPayment = [SELECT Id, Paid_Installments__c, Last_Installment__c, Payment_Mode__c, Status__c FROM Premium_Payment__c
                                                    WHERE Policy_Purchase__c =:policyPurchase.Id
                                                    AND Payment_Mode__c = 'Cheque'
                                                    AND Status__c = 'Processed'];

        for(Premium_Payment__c pymt : updatedPayment){
            System.assertEquals(true, pymt.Last_Installment__c, 'The Last Installment must be marked as true');    
        } 
    }

    @isTest
    static void testPreventFromCreatingMorePaymentDuringInsert() {

        Account policyholder = [SELECT Id, Name FROM Account WHERE Name = 'Test Policyholder'];
        Contact agent = [SELECT Id, LastName FROM Contact WHERE LastName = 'Test Agent'];
        Order policyPurchase = [SELECT Id, AccountId FROM Order WHERE AccountId =:policyholder.Id];

        List<Premium_Payment__c> premiumPaymentList = new List<Premium_Payment__c>();

        for(Integer i=1; i<=100; i++){
            premiumPaymentList.add(
                new Premium_Payment__c(
                    Policy_Purchase__c = policyPurchase.Id,
                    Policyholder__c = policyholder.Id,
                    Agent__c = agent.Id,
                    Payment_Mode__c = 'Cash',
                    Status__c = 'Processed',
                    Verification_Status__c = 'Verified',
                    Payment_Date__c = Date.today() + 30 * i
                )
            );
        }
        insert premiumPaymentList;

        try{
            insert new Premium_Payment__c(
                    Policy_Purchase__c = policyPurchase.Id,
                    Policyholder__c = policyholder.Id,
                    Agent__c = agent.Id,
                    Payment_Mode__c = 'Cash',
                    Status__c = 'Processed',
                    Verification_Status__c = 'Verified',
                    Payment_Date__c = Date.today() + (30)
                );
            System.assert(false);
        }catch(exception e){
            System.assert(true);
        }
    }

    @isTest
    static void testPreventFromCreatingMorePaymentDuringUpdate() {

        Account policyholder = [SELECT Id, Name FROM Account WHERE Name = 'Test Policyholder'];
        Contact agent = [SELECT Id, LastName FROM Contact WHERE LastName = 'Test Agent'];
        Order policyPurchase = [SELECT Id, AccountId FROM Order WHERE AccountId =:policyholder.Id];

        List<Premium_Payment__c> premiumPaymentList = new List<Premium_Payment__c>();

        for(Integer i=1; i<=98; i++){
            premiumPaymentList.add(
                new Premium_Payment__c(
                    Policy_Purchase__c = policyPurchase.Id,
                    Policyholder__c = policyholder.Id,
                    Agent__c = agent.Id,
                    Payment_Mode__c = 'Cheque',
                    Status__c = 'Processed',
                    Payment_Date__c = Date.today() + 30 * i
                )
            );
        }
        insert premiumPaymentList;

        Premium_Payment__c lastPayment = new Premium_Payment__c(
                Policy_Purchase__c = policyPurchase.Id,
                Policyholder__c = policyholder.Id,
                Agent__c = agent.Id,
                Payment_Mode__c = 'Net Banking',
                Status__c = 'Pending',
                Payment_Date__c = Date.today() + (30)
            );
        insert lastPayment;

        try{
            lastPayment.Status__c = 'Processed';
            lastPayment.Verification_Status__c = 'Verified';
            update lastPayment;
            System.assert(false);
        }catch(exception e){
            System.assert(true);
        }
    }
}