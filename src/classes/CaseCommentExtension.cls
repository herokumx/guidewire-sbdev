public with sharing class CaseCommentExtension {
    private final Case caseRec;

    public CaseComment comment {get; set;}

    public CaseCommentExtension(ApexPages.StandardController controller) {
        caseRec = (Case)controller.getRecord();
        comment = new CaseComment();
        comment.parentid = caseRec.id;
        comment.IsPublished = true;
    }
    public PageReference addComment() {
        if(String.isBlank(comment.commentbody)){
            return null;
        }  
        insert comment;
        comment = new CaseComment();
        comment.parentid = caseRec.id;
        comment.IsPublished = true;
        return null;
    }  
}