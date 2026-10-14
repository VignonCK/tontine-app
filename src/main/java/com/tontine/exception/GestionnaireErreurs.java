package com.tontine.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.ModelAndView;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Transforme les exceptions levées par les contrôleurs en pages d'erreur.
 */
@ControllerAdvice
public class GestionnaireErreurs {

    private static final Logger log = LoggerFactory.getLogger(GestionnaireErreurs.class);

    /** Règle de gestion violée : on affiche le message à l'utilisateur. */
    @ExceptionHandler(RegleMetierException.class)
    public ModelAndView regleMetier(RegleMetierException ex) {
        ModelAndView mav = new ModelAndView("error/regle-metier", HttpStatus.UNPROCESSABLE_CONTENT);
        mav.addObject("message", ex.getMessage());
        return mav;
    }

    /** Élément demandé inexistant. */
    @ExceptionHandler(RessourceIntrouvableException.class)
    public ModelAndView ressourceIntrouvable(RessourceIntrouvableException ex) {
        return new ModelAndView("error/404", HttpStatus.NOT_FOUND);
    }

    /**
     * Toute autre exception : erreur complète dans le journal,
     * page 500 générique (aucun détail technique) pour l'utilisateur.
     */
    @ExceptionHandler(Exception.class)
    public ModelAndView erreurInattendue(Exception ex, HttpServletRequest requete) throws Exception {
        // Relancées telles quelles : Spring Security gère les refus d'accès (403)
        // et l'absence de connexion (page de connexion) ; Spring MVC gère ses
        // propres erreurs (adresse inconnue → 404, méthode non permise → 405...).
        if (ex instanceof AccessDeniedException
                || ex instanceof AuthenticationException
                || ex instanceof ErrorResponse) {
            throw ex;
        }
        log.error("Erreur inattendue sur {} {}", requete.getMethod(), requete.getRequestURI(), ex);
        return new ModelAndView("error/500", HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
