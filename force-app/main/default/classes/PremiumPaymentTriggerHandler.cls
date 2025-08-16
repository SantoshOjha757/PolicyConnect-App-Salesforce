/* When premium payment is created, the trigger performs following things:
    1. validate required fields,
    2. count the number of installment paid in the 'Paid Installments' for verified payments,
    3. if the serial number matches to the 'Order.Total Installments' then mark the 'Last Installment' as true,
    4. Also, prevent the user from generating more premium payments than 'Total Installments' value
*/
public with sharing class PremiumPaymentTriggerHandler {

    public static void calculateTotalPayments(List<Premium_Payment__c> premiumPaymentNewList, Map<Id, Premium_Payment__c> premiumPaymentOldMap) {

        Set<Id> policyPurchaseIds = new Set<Id>();
        for(Premium_Payment__c payment : premiumPaymentNewList){

            // new values
            Id policyPurchaseId = payment.Policy_Purchase__c;
            Id policyHolderId = payment.Policyholder__c;
            Id agentId = payment.Agent__c;
            String paymentMode = payment.Payment_Mode__c;
            String paymentStatus = payment.Status__c;
            String paymentVerificationStatus = payment.Verification_Status__c;

            // old values
            String paymentOldStatus;
            String paymentOldVerificationStatus;
            if(premiumPaymentOldMap != null && premiumPaymentOldMap.containsKey(payment.Id)){
                paymentOldStatus = premiumPaymentOldMap.get(payment.Id).Status__c;
                paymentOldVerificationStatus = premiumPaymentOldMap.get(payment.Id).Verification_Status__c;  
            }

            // validating required fields
            if(policyPurchaseId == null || policyHolderId == null || agentId == null || paymentMode == null || paymentStatus == null){
                payment.addError('Required fields must be filled to generate the payment');
            }
            // filtering
            else if (
                // insert
                (premiumPaymentOldMap == null &&
                paymentStatus != null && paymentStatus == 'Processed' &&
                paymentVerificationStatus != null && paymentVerificationStatus == 'Verified')
                ||
                // update
                (premiumPaymentOldMap != null
                && paymentStatus != null && paymentStatus != paymentOldStatus && paymentStatus == 'Processed'
                && paymentVerificationStatus != null && paymentVerificationStatus != paymentOldVerificationStatus && paymentVerificationStatus == 'Verified') ){
                    // collecting the policy purchase Id (lookup Id)
                    policyPurchaseIds.add(payment.Policy_Purchase__c);
            }
        }   

        // getting the policy Id and total installments
        Map<Id, Decimal> totalInstallmentMap = new Map<Id, Decimal>();
        for(Order policyPurchase : [SELECT Id, Total_Installments__c FROM Order WHERE Id IN: policyPurchaseIds WITH USER_MODE]){
            if(policyPurchase.Total_Installments__c != null){
                totalInstallmentMap.put(policyPurchase.Id, policyPurchase.Total_Installments__c);
            }
        }

        // initializing the paymentCounterMap values to 0
        Map<Id, Integer> paymentCounterMap = new Map<Id, Integer>();
        for(Id purchaseId : policyPurchaseIds){
            paymentCounterMap.put(purchaseId, 0);
        }

        // for the first run, the aggregate query returns nothing so the above initialization will work
        // counting the verified payment records
        for(AggregateResult prm : [SELECT COUNT(Id)totalCount, Policy_Purchase__c FROM Premium_Payment__c
                                    WHERE Policy_Purchase__c IN: policyPurchaseIds
                                    AND Status__c = 'Processed' 
                                    AND Verification_Status__c = 'Verified'
                                    WITH USER_MODE
                                    GROUP BY Policy_Purchase__c ]){
                                        // collecting the policy purchase Id and total payment count values
                                        paymentCounterMap.put((Id)prm.get('Policy_Purchase__c'), (Integer)prm.get('totalCount'));
                                    }
        
        for(Premium_Payment__c payment : premiumPaymentNewList){
            // incrementing the number of payments in Paid Installment field
            if(paymentCounterMap.containsKey(payment.Policy_Purchase__c)){
                payment.Paid_Installments__c = paymentCounterMap.get(payment.Policy_Purchase__c) + 1;
            }
            // if any payment exists
            if(payment.Paid_Installments__c > 0 && totalInstallmentMap.containsKey(payment.Policy_Purchase__c)){
                // when paid installment value more than total installment
                if(payment.Paid_Installments__c > totalInstallmentMap.get(payment.Policy_Purchase__c)){
                    // throwing error message
                    payment.addError('The Policyholder has already paid all the installments');
                }
                // when paid installment value matches to the total installment value from policy purchase
                else if(payment.Paid_Installments__c == totalInstallmentMap.get(payment.Policy_Purchase__c)){
                    // setting as last installment
                    payment.Last_Installment__c = true;
                }
            }
        }
    }

    // prevent users from updating, deleting the Premium Payment records when Status = 'Processed' or 'Failed'
    public static void preventChangingPayments(List<Premium_Payment__c> paymentList){
        
        List<User> currentUserList = [SELECT Id FROM User WHERE Profile.Name IN('LIC Agents', 'LIC ADO') WITH USER_MODE];

        Id agentUserId;
        Id adoUserId;

        // filtering userIds
        for(User currentUser : currentUserList){
            if(currentUser.Profile.Name == 'LIC Agents'){
                agentUserId = currentUser.Id;
            } else{
                adoUserId = currentUser.Id;
            }
        }

        for(Premium_Payment__c payment : paymentList){
            // validating
            if(payment.Status__c != null && (UserInfo.getUserId() == agentUserId || UserInfo.getUserId() == adoUserId)){
                if(payment.Status__c == 'Processed'){
                    payment.addError('Payment records can not be updated or deleted if already processed');
                } else if(payment.Status__c == 'Failed'){
                    payment.addError('Payment records can not be updated or deleted if already Failed');
                }
            }
        }
    }
}