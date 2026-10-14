package com.tontine.exception;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.anonymous;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.stereotype.Controller;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Vérifie que chaque type d'exception aboutit au bon statut HTTP et à la bonne page.
 */
@WebMvcTest
@Import(GestionnaireErreursTest.ControleurDeclencheur.class)
@WithMockUser
class GestionnaireErreursTest {

    /** Contrôleur de test uniquement : chaque adresse lève une exception. */
    @Controller
    static class ControleurDeclencheur {

        @GetMapping("/test/regle-metier")
        String regleMetier() {
            throw new RegleMetierException("Ce membre a déjà cotisé pour ce tour.");
        }

        @GetMapping("/test/introuvable")
        String introuvable() {
            throw new RessourceIntrouvableException("Tontine 42 introuvable");
        }

        @GetMapping("/test/inattendue")
        String inattendue() {
            throw new IllegalStateException("détail technique secret");
        }

        @GetMapping("/test/acces-refuse")
        String accesRefuse() {
            throw new AccessDeniedException("refusé");
        }
    }

    @Autowired
    private MockMvc mockMvc;

    @Test
    void regleMetier_affiche_le_message_avec_statut_422() throws Exception {
        mockMvc.perform(get("/test/regle-metier"))
                .andExpect(status().isUnprocessableContent())
                .andExpect(view().name("error/regle-metier"))
                .andExpect(model().attribute("message", "Ce membre a déjà cotisé pour ce tour."))
                .andExpect(content().string(containsString("Ce membre a déjà cotisé pour ce tour.")));
    }

    @Test
    void ressourceIntrouvable_affiche_la_page_404() throws Exception {
        mockMvc.perform(get("/test/introuvable"))
                .andExpect(status().isNotFound())
                .andExpect(view().name("error/404"));
    }

    @Test
    void exceptionInattendue_affiche_la_page_500_sans_detail_technique() throws Exception {
        mockMvc.perform(get("/test/inattendue"))
                .andExpect(status().isInternalServerError())
                .andExpect(view().name("error/500"))
                .andExpect(content().string(not(containsString("détail technique secret"))))
                .andExpect(content().string(not(containsString("IllegalStateException"))));
    }

    @Test
    void accesRefuse_reste_gere_par_spring_security_en_403() throws Exception {
        mockMvc.perform(get("/test/acces-refuse"))
                .andExpect(status().isForbidden());
    }

    @Test
    void adresseInconnue_donne_404_et_non_500() throws Exception {
        mockMvc.perform(get("/adresse-qui-n-existe-pas"))
                .andExpect(status().isNotFound());
    }

    @Test
    void sansConnexion_spring_security_demande_la_connexion() throws Exception {
        // Utilisateur anonyme : refusé par Spring Security avant le contrôleur
        mockMvc.perform(get("/test/inattendue").with(anonymous()))
                .andExpect(status().isUnauthorized());
    }
}
