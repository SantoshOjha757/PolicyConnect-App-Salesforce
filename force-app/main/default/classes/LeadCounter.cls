public with sharing class LeadCounter {
    @AuraEnabled
    public static Integer countTotalConvertedLeads(Id agentUserId) {

        if(agentUserId == null){
            System.debug('no userId is passed');
        }

        List<AggregateResult> leadCount = [SELECT COUNT(Id)totalCount FROM Lead WHERE OwnerId =:agentUserId
                                            AND IsConverted = TRUE
                                            GROUP BY OwnerId];

        for(AggregateResult aggr : leadCount){
            return (Integer)aggr.get('totalCount');
        }
        return 0;
    }
}