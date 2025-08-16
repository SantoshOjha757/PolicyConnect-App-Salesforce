trigger AgentTrigger on Contact (after insert, before delete) {
    if(trigger.isAfter){
        if(trigger.isInsert)
        {
            AgentTriggerHandler.createAgentUserRecord(trigger.new);
            
        }
    }
    
    if(trigger.isBefore){
        if(Trigger.isDelete)
        {
            ContactClassHandler.handleBeforeDelete(Trigger.New);
        }
    }
}