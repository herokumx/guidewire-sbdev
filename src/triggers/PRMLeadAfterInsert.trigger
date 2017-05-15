trigger PRMLeadAfterInsert on Lead (before insert) {
    
    PRMLead PRMLeadhelper = new PRMLead();
    
      if(trigger.isinsert) {
          PRMLeadhelper.AddReferringPartner(Trigger.new);
      }
}