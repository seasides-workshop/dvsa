package in.yadhu.util.util;

import java.io.IOException;

/**
 * Internal/private validation utility - published only to private Nexus.
 */
public final class InternalValidator {

    private InternalValidator() {}

    /**
     * Validates that a filename is safe for use (internal policy).
     */
    public static String sanitizeFilename(String filename) {
        if (filename == null || filename.isBlank()) {
            return "default.txt";
        }
        String trimmed = filename.trim();
        if (trimmed.length() > 255) {
            return trimmed.substring(0, 255);
        }
        return trimmed;
    }
}
