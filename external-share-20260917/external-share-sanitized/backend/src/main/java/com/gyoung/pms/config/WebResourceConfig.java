package com.gyoung.pms.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebResourceConfig implements WebMvcConfigurer {

    private final String staticLocation;

    public WebResourceConfig(@Value("${pms.web.static-location:../app/}") String staticLocation) {
        this.staticLocation = staticLocation.endsWith("/") ? staticLocation : staticLocation + "/";
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/**")
                .addResourceLocations("file:" + staticLocation)
                .setCachePeriod(0);
    }
}
