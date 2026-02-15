package in.yadhu.dvsa.controller;

import in.yadhu.util.util.InternalValidator;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    private static final Logger LOGGER = LoggerFactory.getLogger(HelloController.class);

    @GetMapping("/")
    public String hello(@RequestParam(required = false) String filename) {
        System.out.println("filename: " + filename);
        LOGGER.info("Hello endpoint accessed with filename: {}", filename);
        
        if (filename != null) {
            LOGGER.info("Filename provided: {}", filename);
            String sanitized = InternalValidator.sanitizeFilename(filename);

            if (StringUtils.isNotBlank(sanitized)) {
                return "Filename validated: " + sanitized;
            }
            
            return "Error: Invalid filename";
        }
        
        return "Hello from Spring Boot! Provide ?filename=example.txt to validate";
    }

    @GetMapping("/health")
    public String health() {
        LOGGER.debug("Health check endpoint accessed");
        return "OK";
    }

}

