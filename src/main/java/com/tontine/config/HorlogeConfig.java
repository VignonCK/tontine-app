package com.tontine.config;

import java.time.Clock;
import java.time.ZoneId;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Fournit l'horloge de l'application.
 *
 * On injecte un Clock dans les services au lieu d'appeler LocalDate.now()
 * directement : en test, on peut alors remplacer ce bean par Clock.fixed(...)
 * et contrôler la date « du jour » (échéances, retards de cotisation...).
 */
@Configuration
public class HorlogeConfig {

    /** Fuseau de référence de la tontine (Bénin, UTC+1). */
    private static final ZoneId FUSEAU = ZoneId.of("Africa/Porto-Novo");

    /**
     * Horloge système réglée sur le fuseau du Bénin.
     * Utilisation : LocalDate.now(clock) plutôt que LocalDate.now().
     */
    @Bean
    public Clock clock() {
        return Clock.system(FUSEAU);
    }
}
