package in.yadhu.dvsa;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DvsaApplication {

    private static final Logger LOGGER = LoggerFactory.getLogger(DvsaApplication.class);

    public static void main(String[] args) {
        LOGGER.info("Starting DVSA Application");
        SpringApplication.run(DvsaApplication.class, args);
        LOGGER.info("DVSA Application started successfully");
    }

}

