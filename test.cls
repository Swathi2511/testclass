@IsTest
private class ClassClsTest {
    @IsTest
    static void testCalculateScoreWithoutBonus() {
        System.assertEquals(7, ClassCls.calculateScore(7, 4, false));
        System.assertEquals(0, ClassCls.calculateScore(null, 4, false));
    }

    @IsTest
    static void testCalculateScoreWithBonusAndNegativeGuard() {
        System.assertEquals(10, ClassCls.calculateScore(7, 3, true));
        System.assertEquals(2, ClassCls.calculateScore(2, null, true));
        System.assertEquals(0, ClassCls.calculateScore(-5, 1, true));
    }

    @IsTest
    static void testClassifyTextBranches() {
        System.assertEquals('BLANK', ClassCls.classifyText(null));
        System.assertEquals('BLANK', ClassCls.classifyText('   '));
        System.assertEquals('SINGLE_CHAR', ClassCls.classifyText(' a '));
        System.assertEquals('UPPERCASE', ClassCls.classifyText(' HELLO '));
        System.assertEquals('MIXED', ClassCls.classifyText('Hello'));
    }
}
