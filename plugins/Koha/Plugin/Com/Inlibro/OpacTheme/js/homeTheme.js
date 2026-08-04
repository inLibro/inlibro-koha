document.addEventListener('DOMContentLoaded', function () {
    const themeSelect = document.getElementById('theme-select');

    const noelOptions = document.getElementById('noel-config');
    const valentinOptions = document.getElementById('valentin-config');
    const halloweenOptions = document.getElementById('halloween-config');
    const toggleNoel = document.getElementById('toggle_noel');
    const toggleStValentin = document.getElementById('toggle_stValentin');
    const togglehalloween = document.getElementById('toggle_halloween');
    const togglefantome = document.getElementById('toggle_halloween2');
    const togglePaque = document.getElementById('toggle_paque');

    const activationFlocons = document.getElementById('activation_flocons');
    const vitesseFlocons = document.getElementById('vitesse_flocons');
    const tailleFlocons = document.getElementById('taille_flocons');
    const ventFlocons = document.getElementById('vent_flocons');
    const quantiteFlocons = document.getElementById('quantite_flocons');
    
    const activationCoeurs = document.getElementById('activation_coeurs');
    const vitesseCoeurs = document.getElementById('vitesse_coeurs');
    const tailleCoeurs = document.getElementById('taille_coeurs');
    const ventCoeurs = document.getElementById('vent_coeurs');
    const quantiteCoeurs = document.getElementById('quantite_coeurs');
    
    const activationSpiders = document.getElementById('activation_spiders');
    const quantiteSpiders = document.getElementById('quantite_spiders');
    const activationGhost = document.getElementById('activation_ghost');

    const activationEggs = document.getElementById('activation_eggs');

    const successMessage = document.getElementById('success-message');
    const erreurMessage = document.getElementById('erreur-message');
    const form = document.getElementById('theme-form');

  function updateThemeOptions() {
    // Masquer tous les toggles
    toggleNoel.style.display = 'none';
    toggleStValentin.style.display = 'none';
    togglehalloween.style.display = 'none';
    togglefantome.style.display = 'none';
    togglePaque.style.display = 'none';

    switch (themeSelect.value) {
        case 'noel':
            toggleNoel.style.display = 'block';
            break;
        case 'saint-valentin':
            toggleStValentin.style.display = 'block';
            break;
        case 'halloween':
            togglehalloween.style.display = 'block';
            togglefantome.style.display = 'block'; 
            break;
        case 'paque':
            togglePaque.style.display = 'block';
            break;
    }
    activationFlocons.dispatchEvent(new Event('change'));
    activationCoeurs.dispatchEvent(new Event('change'));
    activationSpiders.dispatchEvent(new Event('change'));
    activationEggs.dispatchEvent(new Event('change'));
}

    updateThemeOptions();
    themeSelect.addEventListener('change', updateThemeOptions);

    form.addEventListener('submit', async function (event) {
        event.preventDefault();

        const formData = new FormData();

        formData.append('plugin_name', 'OpacTheme');
        formData.append('class', 'Koha::Plugin::OpacTheme');
        formData.append('method', 'apply_theme');
        formData.append('action', 'apply_theme');

        const theme = themeSelect.value;
        formData.append('theme', theme);

        switch (theme) {
            case 'noel':
                formData.append('activation_flocons', activationFlocons.checked ? 'on' : 'off');
                formData.append('vitesse_flocons', vitesseFlocons.value);
                formData.append('taille_flocons', tailleFlocons.value);
                formData.append('vent_flocons', ventFlocons.value);
                formData.append('quantite_flocons', quantiteFlocons.value);
                break;
            case 'saint-valentin':
                formData.append('activation_coeurs', activationCoeurs.checked ? 'on' : 'off');
                formData.append('vitesse_coeurs', vitesseCoeurs.value);
                formData.append('taille_coeurs', tailleCoeurs.value);
                formData.append('vent_coeurs', ventCoeurs.value);
                formData.append('quantite_coeurs', quantiteCoeurs.value);
                break;
            case 'halloween':
                formData.append('activation_spiders', activationSpiders.checked ? 'on' : 'off');
                formData.append('quantite_spiders', quantiteSpiders.value);
                formData.append('activation_ghost', activationGhost.checked ? 'on' : 'off');
                break;  
            case 'paque':
                formData.append('activation_eggs', activationEggs.checked ? 'on' : 'off');
                break;
        }

        try {
            const response = await fetch('/cgi-bin/koha/plugins/run.pl/run.pl?Koha::Plugin::OpacTheme&method=apply_theme', {
                method: 'POST',
                body: formData
            });

            if (response.ok) {
                successMessage.style.display = 'block';
                setTimeout(() => successMessage.style.display = 'none', 3000);
            } else {
                erreurMessage.style.display = 'block';
                setTimeout(() => erreurMessage.style.display = 'none', 3000);
            }
        } catch (error) {
            console.error(error);
            erreurMessage.style.display = 'block';
            setTimeout(() => erreurMessage.style.display = 'none', 3000);
        }
    });

   function toggleConfig(toggle, config, themeName) {
    function updateDisplay() {
        const currentTheme = themeSelect.value;
        config.style.display = (currentTheme === themeName && toggle.checked) ? 'block' : 'none';
    }

    toggle.addEventListener('change', updateDisplay);
    updateDisplay(); 
}

toggleConfig(activationFlocons, noelOptions, 'noel');
toggleConfig(activationCoeurs, valentinOptions, 'saint-valentin');
toggleConfig(activationSpiders, halloweenOptions, 'halloween');

// Slider value display
document.getElementById('quantite_flocons').addEventListener('input', function () {
    document.getElementById('val_quantite_flocons').textContent = this.value;
});
document.getElementById('quantite_coeurs').addEventListener('input', function () {
    document.getElementById('val_quantite_coeurs').textContent = this.value;
});
document.getElementById('quantite_spiders').addEventListener('input', function () {
    document.getElementById('val_quantite_spiders').textContent = this.value;
});
});
