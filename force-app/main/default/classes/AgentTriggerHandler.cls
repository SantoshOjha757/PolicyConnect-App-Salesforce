public with sharing class AgentTriggerHandler {

    // prevent users from deleting agent record
    public static void handleBeforeDelete(List<Contact> newRecords)
    {
        Id currentUserId = UserInfo.getUserID();
        Id agentUserId = [SELECT ID, Profile.Name FROM User Where Profile.Name = 'LIC Agents'].ID;
            
        for(Contact con: newRecords)
        {
            if(agentUserID != currentUserId)
            {
                con.addError('You can only view the record but cannot delete it');
            }
        }
    }

    /* when a agent record is created,
        create a user record and populate the LIC_Agent__c with the Agent User Id
    */
    public static void createAgentUserRecord(List<Contact> agentList) {

        List<User> agentUserListToInsert = new List<User>();
        Map<Id, User> agentIdToAgentUserMap = new Map<Id, User>();

        List<AgentConfigue__mdt> agentConfiguration = [SELECT Id, DeveloperName, Agent_Profile_ID__c, UserRoleID__c, UserLincenseID__c 
                                                    FROM AgentConfigue__mdt LIMIT 1];

        for(Contact agent : agentList){
            if(agent.FirstName != null && agent.LastName != null && agent.Phone != null && agent.Email != null){
                // creating new user
                User agentUser = new User();
                agentUser.FirstName = agent.FirstName;
                agentUser.LastName = agent.LastName;
                agentUser.Phone = agent.Phone;
                agentUser.Email = agent.Email;
                agentUser.Username = agent.Email.endsWith('@') + 'sfdc.com';
                agentUser.alias = agent.LastName.substring(0, Math.min(6, agent.LastName.length()));
                agentUser.TimeZoneSidKey = 'Asia/Kolkata';
                agentUser.LanguageLocaleKey = 'en_US';
                agentUser.LocaleSidKey = 'en_IN';
                agentUser.EmailEncodingKey = 'UTF-8';
                agentUser.ProfileId = agentConfiguration[0].Agent_Profile_ID__c;
                agentUser.UserRoleId = agentConfiguration[0].UserRoleID__c;
            //    agentUser.LicenseId = agentConfiguration.UserLincenseID__c;

                agentUserListToInsert.add(agentUser);
                agentIdToAgentUserMap.put(agent.Id, agentUser);
            }
            // else{
            //     agent.addError('Complete the required fields');
            // }
        }

        List<Contact> agentListToUpdate = new List<Contact>();

        if(!agentUserListToInsert.isEmpty()){
            insert agentUserListToInsert;

            Integer idx = 0;
            // updating the LIC_Agent__c field
            if(!agentIdToAgentUserMap.isEmpty()){
                for(Id agentId : agentIdToAgentUserMap.keySet()){
                    Contact existingAgent = new Contact();
                    existingAgent.Id = agentId;
                    existingAgent.LIC_Agent__c = agentUserListToInsert[idx].Id;
                    agentListToUpdate.add(existingAgent);
                    idx++;
                }
            }
        }

        if(!agentListToUpdate.isEmpty()){
            update agentListToUpdate;
        }
    }
}