@isTest
private class LeadCounterTest {
    @testSetup
    static void setupData(){
        //create user
        User usr = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test_user@email.com',
            UserName = 'test_user_' + DateTime.Now().getTime() + '@sfdc.com',
            Alias = 'tuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8'
        );
        insert usr;

        //create agent
        Contact agent = new Contact(
            LastName = 'T Agent',
            LIC_Agent__c = usr.Id
        );
        insert agent;
    }

    // assumption: Test when a user is creating and converting the lead. The count should return 1 as conversion count.
    @isTest
    static void testLeadsCountWhenConverted() {
       
        User testUser = [SELECT Id, Alias FROM User WHERE Alias = 'tuser' LIMIT 1];
        Contact testAgent = [SELECT Id, LIC_Agent__c FROM Contact WHERE LastName = 'T Agent' LIMIT 1];

        Test.startTest();
        System.runAs(testUser){
            // create and convert lead as test user
            Lead ld = new Lead(
                FirstName = 'Test',
                LastName = 'Lead_1',
                Status = 'Open - Not Contacted',
                Expected_Revenue__c = 200000,
                Preferred_Language__c = 'English',
                PAN_Number__c = 'TEST000111'
            );
            insert ld;

            // getting the lead convert field
            List<LeadStatus> convertStatusField = [SELECT Id, ApiName FROM LeadStatus WHERE IsConverted=true LIMIT 1];

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(ld.Id);
            lc.setConvertedStatus(convertStatusField[0].ApiName);

            Database.LeadConvertResult cr = Database.ConvertLead(lc, true);
        }
        
        Integer conversionCount = LeadCounter.countTotalConvertedLeads(testAgent.LIC_Agent__c);
        Test.stopTest();
       
        System.assertEquals(1, conversionCount, 'Count value should be 1');
    }

    // assumption: Test when a user is creating but not converting the lead. The count should return 0 as conversion count.
    @isTest
    static void TestLeadsCountWhenNotConverted() {

        User testUser = [SELECT Id, Alias FROM User WHERE Alias = 'tuser' LIMIT 1];
        Contact testAgent = [SELECT Id, LIC_Agent__c FROM Contact WHERE LastName = 'T Agent' LIMIT 1];

        Test.startTest();

            Lead ld = new Lead(
                FirstName = 'Test',
                LastName = 'Lead_2',
                Status = 'Open - Not Contacted',
                Expected_Revenue__c = 300000,
                Preferred_Language__c = 'English',
                PAN_Number__c = 'TEST000112'
            );
            insert ld;

        Integer conversionCount = LeadCounter.countTotalConvertedLeads(testAgent.LIC_Agent__c);
        Test.stopTest();

        System.assertEquals(0, conversionCount, 'The count value should be 0');
    }
}