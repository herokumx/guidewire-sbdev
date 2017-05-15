/*
 * Developer: Janella Espiritu <janellae@slalomconsulting.com>
 * Description:
 *    Controller to fetch and create CC Review objects related to a sku. To be used on the PDP by default.
 */
global with sharing class MP_ReviewsCtrl {
    global String SKU {get;set;}
    //global List<ccrz__E_Review__c> reviewList {get;set;}
    global String emptyStr {get{return '';}set;}
    //global list<cc_bean_review > reviews { get { if(reviews == null) {reviews = new list<cc_bean_review >();} return reviews; } set; }
    global static String REVIEW_LIST = 'reviews';
  global String extendedProdJSON {get;set;}
    global Boolean reviewAccess {get;set;}
    
    global MP_ReviewsCtrl() {
        reviewAccess = false;
        
        User u = [select Id, Contact.Account.Recordtype.Name, Contact.Account.Alliance_Type__c, ContactId, Contact.MP_Certified__c from User where Id =: UserInfo.getUserId()];

      //  Integer i = [select count() from CS_Asset_Contact_Permissions__c Where CS_Contact__c =:u.ContactId  and CS_Access_Type__c ='Certified'];

        if(u.Contact.Account.Recordtype.Name == 'Customer'){
            reviewAccess = true;
        }
        else if(u.Contact.Account.Recordtype.Name == 'Partner'){
            if(u.Contact.Account.Alliance_Type__c == 'PartnerConnect - Solution'){
                reviewAccess = false;
            }
            else if(u.Contact.Account.Alliance_Type__c == 'PartnerConnect - Consulting'){
             // if(i>0 || u.Contact.MP_Certified__c == true){
                if(u.Contact.MP_Certified__c == true){
                    reviewAccess = true;
                }else{
                    reviewAccess = false;
                }
            }
        }
        
        SKU = ApexPages.currentPage().getParameters().get('sku');
        
        try{
            ccrz__E_Product__c product = [SELECT Id, 
                                              MP_VideoURL__c, 
                                              ccrz__NumberOfReviews__c, 
                                              ccrz__LongDescRT__c, 
                                              ccrz__AverageRating__c 
                                          FROM ccrz__E_Product__c WHERE ccrz__SKU__c = :SKU LIMIT 1];
            final Map<String,Object> customProdData = new Map<String,Object>{
                'videoURL'=>product.MP_VideoURL__c,
                'avgRating'=>product.ccrz__AverageRating__c,
                'NumberOfReviews'=>product.ccrz__NumberOfReviews__c,
                'LongDesc' => product.ccrz__LongDescRT__c
            };   
            extendedProdJSON = JSON.serialize(new Map<String,Object>{
                 'extProdData' => customProdData
            });
        }
        catch(Exception e){
            extendedProdJSON = '';
        }

    }

    @RemoteAction
    global static ccrz.cc_RemoteActionResult fetchReviews(ccrz.cc_RemoteActionContext ctx,String sku){
        ccrz.ccLog.log('fetchingReviews----');
        ccrz.cc_CallContext.initRemoteContext(ctx);
        ccrz.cc_RemoteActionResult result = new ccrz.cc_RemoteActionResult();
        result.inputContext = ctx;
        result.success = false;
        List<cc_bean_review> reviewBeanList = new List<cc_bean_review>();
        try{
            List<ccrz__E_Review__c> reviewList  = [select ccrz__Product__c,ccrz__Rating__c,ccrz__RatingCode__c,
                    ccrz__ReviewDate__c,ccrz__ReviewId__c,ccrz__Status__c,ccrz__Subject__c,ccrz__User__c,
                    ccrz__User__r.FirstName,ccrz__User__r.LastName,ccrz__UserReview__c from ccrz__E_Review__c
                    where ccrz__Status__c = 'Accepted' and ccrz__Product__r.ccrz__SKU__c =:SKU];
            ccrz.ccLog.log('reviewList.size: ' + reviewList.size());
            if(reviewList != null && reviewList.size() >0){
                for(ccrz__E_Review__c item:reviewList){
                    cc_bean_review reviewBean = new cc_bean_review();
                    reviewBean.userReview = item.ccrz__UserReview__c;
                    reviewBean.subject = item.ccrz__Subject__c;
                    reviewBean.userName = item.ccrz__User__r.FirstName + ' ' + item.ccrz__User__r.LastName;
                    reviewBean.reviewDate = item.ccrz__ReviewDate__c.format();
                    reviewBean.rating = item.ccrz__Rating__c;
                    reviewBean.diffRating = 5 - item.ccrz__Rating__c;
                    reviewBeanList.add(reviewBean);
                }
            }
        }
        catch(Exception e){
            result.data = new List<cc_bean_review>();
            result.success = false;
        }

        //result.data = reviewBeanList;
        result.data = new Map<String,Object>{ REVIEW_LIST => reviewBeanList};
        result.success = true;
        System.debug(LoggingLevel.INFO,'@@result.data='+ result.data);
        return result;
    }

    @RemoteAction
    global static ccrz.cc_RemoteActionResult saveReview(ccrz.cc_RemoteActionContext ctx,String sku,String subject,String reviewText,String rating){
        ccrz.cc_CallContext.initRemoteContext(ctx);
        ccrz.cc_RemoteActionResult result = new ccrz.cc_RemoteActionResult();
        result.inputContext = ctx;
        result.success = false;
        try{
            System.debug(LoggingLevel.INFO,'@@ccrz.cc_CallContext.currUserId='+ ccrz.cc_CallContext.currUserId);
            if(String.isNotEmpty(sku)){
                ccrz__E_Product__c prod = [select id from ccrz__E_Product__c where ccrz__SKU__c =:sku limit 1];
                ccrz__E_Review__c review = new ccrz__E_Review__c();
                review.ccrz__Product__c = prod.Id;
                review.ccrz__Status__c = 'New';
                review.ccrz__Subject__c = subject;
                review.ccrz__UserReview__c = reviewText;
                review.ccrz__User__c = ccrz.cc_CallContext.currUserId;
                review.ccrz__RatingCode__c = rating;
                insert review;
                result.success = true;
            }

        }
        catch(Exception e){
            ccrz.ccLog.log('@@Error Saving = '+ e.getStackTraceString());
            System.debug(LoggingLevel.INFO,'@@Error='+ e.getStackTraceString());
        }

        return result;
    }

    public class cc_bean_review{
        public string userReview {get; set; }
        public string subject {get; set; }
        public string reviewId {get; set; }
        public String reviewDate { get; set; }
        public double rating {get; set; }
        public double helpfulCount {get; set;}
        public double numberOfViewers {get; set;}
        public DateTime createdDate { get; set; }
        public DateTime lastModifiedDate { get; set; }
        public string productId {get; set; }
        public string userName { get; set; }
        public double diffRating { get; set; }        

        public cc_bean_Review(){diffRating = 0;}
    }

}