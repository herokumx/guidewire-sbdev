public with sharing class CS_CaseFeedExtension {
    private final Case caseRec;

    public FeedItem feed {get; set;}

    public CS_CaseFeedExtension(ApexPages.StandardController controller) {
        caseRec = (Case)controller.getRecord();
        feed = new FeedItem();
        feed.parentid = caseRec.id;
        feed.Type = 'TextPost';
        feed.Visibility = 'InternalUsers';
    }
    public PageReference addComment() {
        if(String.isBlank(feed.body)){
            return null;
        }  
        insert feed;
        feed = new FeedItem();
        feed.parentid = caseRec.id;
        feed.Visibility = 'InternalUsers';
        feed.Type = 'TextPost';
        return null;
    }  
}