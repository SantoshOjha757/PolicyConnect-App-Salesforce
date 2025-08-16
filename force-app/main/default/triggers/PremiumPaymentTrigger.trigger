trigger PremiumPaymentTrigger on Premium_Payment__c(before insert, before update, before delete) {
    if(trigger.isBefore){
        if(trigger.isinsert){
            PremiumPaymentTriggerHandler.calculateTotalPayments(trigger.new, null);
        }
        if(trigger.isUpdate){
            PremiumPaymentTriggerHandler.calculateTotalPayments(trigger.new, trigger.oldMap);
            PremiumPaymentTriggerHandler.preventChangingPayments(trigger.new);
        }
        if(trigger.isDelete){
            PremiumPaymentTriggerHandler.preventChangingPayments(trigger.old);
        }
    }
}