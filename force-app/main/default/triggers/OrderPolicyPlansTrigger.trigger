trigger OrderPolicyPlansTrigger on OrderItem (after insert, after update) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            OrderPolicyPlanTriggerHandler.updatePolicyPurchase(trigger.new, null);
        }
        if(trigger.isUpdate){
            OrderPolicyPlanTriggerHandler.updatePolicyPurchase(trigger.new, trigger.oldMap);
        }
    }
}