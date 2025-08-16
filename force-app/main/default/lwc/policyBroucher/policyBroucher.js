import { LightningElement, wire } from 'lwc';
import {getObjectInfo, getPicklistValues} from 'lightning/uiObjectInfoApi';
import {NavigationMixin} from 'lightning/navigation';
import POLICY_PLAN_OBJECT from '@salesforce/schema/Product2';
import CATEGORY_FIELD from '@salesforce/schema/Product2.Category__c';

import getPlanNames from '@salesforce/apex/PolicyPlans.getPlanNames';
import getBroucherURL from '@salesforce/apex/PolicyPlans.getBroucherURL';

export default class PolicyBroucher extends NavigationMixin(LightningElement) {

    values;
    policyPlanDefaultRecordTypeId;
    categoryValues;
    displayPlanNames = false;
    planNameList;
    valuesPlanNames;
    displayBroucher = false;
    broucherUrl;

    get options(){
        return this.categoryValues;
    }

    get optionsPlanNames(){
        return this.planNameList;
    }

    @wire(getObjectInfo, {objectApiName: POLICY_PLAN_OBJECT})
    wiredPolicyPlanObjectInfo({data, error}){
        if(data){
            console.log('wiredPolicyPlanObjectInfo.data : ', data.defaultRecordTypeId);
            this.policyPlanDefaultRecordTypeId = data.defaultRecordTypeId;
        }
    }

    @wire(getPicklistValues, {recordTypeId:'$policyPlanDefaultRecordTypeId', fieldApiName: CATEGORY_FIELD})
    wiredPolicyPlanCategories({data, error}){
        if(data){
            console.log('category picklist values : ', data.values);
            this.categoryValues = data.values;
            console.log('this.categoryValues : ', this.categoryValues);
        } else{
            console.log('error occured while getting the picklist values', error);
        }
    }

    handleCategoriesChange(event){
        this.values = event.detail.value;
        this.displayPlanNames = true;

        if(this.displayPlanNames == true){
            getPlanNames({policyCategory: this.values})
            .then(result =>{
                if(result != null){
                    console.log('plan names as result : ', result);
                    const namedList = result.map(eachName =>{
                        return {label: eachName, value: eachName};
                    });
                    this.planNameList = namedList;
                }
            }).catch(error =>{
                console.log('error occured while getting the plan names : ', error);
            });
        }
    }

    handlePlanChange(event){
        this.valuesPlanNames = event.detail.value;

        if(this.valuesPlanNames != null){
            getBroucherURL({planName: this.valuesPlanNames})
            .then(result =>{
                console.log('broucher link : ', result);
                this.broucherUrl = result;
            }).catch(error =>{
                console.log('error occured while getting the broucher link : ', error);
            })
        }
    }

    handleViewButtonClick(){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.broucherUrl
            }
        })
    }
}