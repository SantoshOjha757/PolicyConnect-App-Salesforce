import { LightningElement, api, wire } from 'lwc';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
import countTotalConvertedLeads from '@salesforce/apex/LeadCounter.countTotalConvertedLeads'; 

import AGENT_USER_ID from '@salesforce/schema/Contact.LIC_Agent__c';

export default class LeadConversionCounterAgentWise extends LightningElement {

    @api recordId;
    userId;
    totalConvertedLeads;

    @wire(getRecord, {recordId: '$recordId', fields: [AGENT_USER_ID]})
    wiredAgentUserId({data, error}){
        if(data){
            this.userId = getFieldValue(data, AGENT_USER_ID);
            console.log('userId : ', this.userId);

            if(this.userId != null){
                countTotalConvertedLeads({agentUserId:this.userId})
                .then(result =>{
                    console.log('number count : ', result);
                    this.totalConvertedLeads = result;
                })
                .catch(error =>{
                    console.log('error in the count : ', error);
                })
            }
        }
        else {
            console.log('error occured while getting the userId : ', error);
        }
    }
}