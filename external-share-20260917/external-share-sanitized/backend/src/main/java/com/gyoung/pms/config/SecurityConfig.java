package com.gyoung.pms.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.factory.PasswordEncoderFactories;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
class SecurityConfig {
    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http.csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth.requestMatchers(
                                "/", "/index.html", "/css/**", "/js/**", "/actuator/health/**")
                        .permitAll()
                        .requestMatchers("/api/admin/**").hasRole("ADMIN")
                        .requestMatchers("/api/**").authenticated()
                        .anyRequest().permitAll())
                .httpBasic(basic -> {})
                .build();
    }

    @Bean
    UserDetailsService users(@Value("${pms.auth.user-name}") String userName,
                             @Value("${pms.auth.user-password}") String userPassword,
                             @Value("${pms.auth.admin-name}") String adminName,
                             @Value("${pms.auth.admin-password}") String adminPassword) {
        if (userName.isBlank() || userPassword.isBlank() || adminName.isBlank() || adminPassword.isBlank()) {
            throw new IllegalStateException("Set PMS_LOCAL_USER_NAME/PASSWORD and PMS_LOCAL_ADMIN_NAME/PASSWORD");
        }
        PasswordEncoder encoder = PasswordEncoderFactories.createDelegatingPasswordEncoder();
        return new InMemoryUserDetailsManager(
                User.withUsername(userName).password(encoder.encode(userPassword)).roles("USER").build(),
                User.withUsername(adminName).password(encoder.encode(adminPassword)).roles("ADMIN", "USER").build());
    }
}
