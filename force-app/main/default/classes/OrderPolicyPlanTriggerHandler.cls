public with sharing class OrderPolicyPlanTriggerHandler {
    // once a new Order Policy Plan (Order Product) is created,
    // update the Policy Plan Name, Total Installments, Installment Amount, Premium Term Range in Policy Purchase(Order)

    public static void updatePolicyPurchase(List<Orderitem> orderPolicyPlanNewList, Map<Id, Orderitem> orderPolicyPlanOldMap) {

        Set<Id> policyPlanIdSet = new Set<Id>();

        for(OrderItem ori : orderPolicyPlanNewList){
            // differentiating the new values and old values
            Decimal totalInstallmentsNew = ori.Quantity;
            Decimal totalInstallmentsOld = orderPolicyPlanOldMap.get(ori.Id).Quantity;

            Decimal installmentAmountNew = ori.UnitPrice;
            Decimal installmentAmountOld = orderPolicyPlanOldMap.get(ori.Id).UnitPrice;

            // filtering the insert (top) and update operation (bottom)
            if((orderPolicyPlanOldMap == null && ori.OrderId != null && ori.Product2Id != null && totalInstallmentsNew != null && totalInstallmentsNew != totalInstallmentsOld) ||

                (orderPolicyPlanOldMap != null && ori.OrderId != null && ori.Product2Id != null && totalInstallmentsNew != null && totalInstallmentsNew != totalInstallmentsOld && installmentAmountNew != null && installmentAmountNew != installmentAmountOld)){
                    
                    // collecting the Policy Plans Ids (Product Ids) 
                    policyPlanIdSet.add(ori.Product2Id);
            }
        }

        // getting the Policy Plans(Product) records
        Map<Id, Product2> policyPlansMap = new Map<Id, Product2>();

        for(Product2 policyPlan : [SELECT Id, Name, Policy_Term_Range__c FROM Product2 WHERE Id IN: policyPlanIdSet]){
            if(!policyPlansMap.containsKey(policyPlan.Id)){
                policyPlansMap.put(policyPlan.Id, policyPlan);
            }
        }

        // updating the Policy Plan Name, Total Installments, Installment Amount, Premium Term Range in Policy Purchase(Order)
        List<Order> policyPurchaseListToUpdate = new List<Order>();

        for(OrderItem ori : orderPolicyPlanNewList){
            if(policyPlansMap.containsKey(ori.Product2Id)){
                // updating the Policy Purchase field values
                Order odr = new Order();
                odr.Id = ori.OrderId;
                odr.Test_Policy_Name__c = policyPlansMap.get(ori.Product2Id).Name;
                odr.Total_Installment__c =  ori.Quantity;
                odr.Installment_Amount__c = ori.UnitPrice;

                // addiing the updated orders
                policyPurchaseListToUpdate.add(odr);
            }
        }
        
        //updateing the orders
        if(!policyPurchaseListToUpdate.isEmpty()){
            update policyPurchaseListToUpdate;
        }
    }
}