package com.tontine.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Page d'accueil provisoire (vitrine de la charte graphique).
 * Sera remplacée par le module 1.
 */
@Controller
public class AccueilController {

    @GetMapping("/")
    public String accueil() {
        return "index";
    }
}
