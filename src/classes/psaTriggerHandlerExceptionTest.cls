@isTest
private class psaTriggerHandlerExceptionTest {
	
	@isTest static void test_method_one() {
		try{
			throwTriggerException();
		}catch(psaTriggerHandlerException e){
			System.debug('Caught exception');
		}
	}

	private static void throwTriggerException(){
		psaTriggerHandlerException pe = new psaTriggerHandlerException('Error', true);
		throw pe;
	}
	
	@isTest static void test_method_two() {
		// Implement test code
	}
	
}