public with sharing class PolicyPlans {
    @AuraEnabled
    public static List<String> getPlanNames(String policyCategory) {
        List<Product2> policyPlans = [SELECT Id, Name, Category__c FROM Product2
                                        WHERE Category__c =:policyCategory];

        if(policyPlans.isEmpty()){
            return null;
        }

        List<String> policyNames = new List<String>();
        for(Product2 policyPlan : policyPlans){
            policyNames.add(policyPlan.Name);
        }

        if(!policyNames.isEmpty()){
            return policyNames;
        }
        return new List<String>{'No such plan found'};
    }

    @AuraEnabled
    public static String getBroucherURL(String planName){
        if(planName == null){
            return 'Plan name is empty';
        }

        Product2 broucherURL = [SELECT Name, Broucher_Link__c FROM Product2
                                WHERE Name =: planName
                                LIMIT 1];

        if(broucherURL.Broucher_Link__c != null){
            return broucherURL.Broucher_Link__c;
        }
        return 'No such image link found';        
    }
}