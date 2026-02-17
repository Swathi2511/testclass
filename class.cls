public with sharing class ClassCls {
    public static Integer calculateScore(Integer baseScore, Integer bonus, Boolean includeBonus) {
        Integer safeBase = (baseScore == null) ? 0 : baseScore;
        Integer safeBonus = (bonus == null) ? 0 : bonus;

        if (!includeBonus) {
            return safeBase;
        }

        Integer total = safeBase + safeBonus;
        if (total < 0) {
            return 0;
        }

        return total;
    }

    public static String classifyText(String value) {
        if (String.isBlank(value)) {
            return 'BLANK';
        }

        String normalized = value.trim();
        if (normalized.length() == 1) {
            return 'SINGLE_CHAR';
        }

        if (normalized == normalized.toUpperCase()) {
            return 'UPPERCASE';
        }

        return 'MIXED';
    }
}
