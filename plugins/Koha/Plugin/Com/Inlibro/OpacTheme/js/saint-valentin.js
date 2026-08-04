document.addEventListener('DOMContentLoaded', function() {
    
    // 2. Script des coeurs
    var options = window.StValentinThemeOptions || {};
    var vitesse = options.vitesse || 'normal';  
    var taille = options.taille || 'normal';   
    var vent = options.vent || 'null';   
    var activation = options.activation_coeurs || "on";
    var quantite = parseInt(options.quantite_coeurs) || 10;
     console.log(activation);

    var vitesseCoeff = 0.1; 
    switch(vitesse) {
        case 'slow': vitesseCoeff = 0.05; break;
        case 'quick': vitesseCoeff = 0.2; break;
    }

    var tailleCoeff = 10; 
    switch(taille) {
        case 'small': tailleCoeff = 5; break;
        case 'big': tailleCoeff = 20; break;
    }

    var ventCoeff = 0; 
    switch(vent) {
        case 'normal': ventCoeff = 2; break;
        case 'alot': ventCoeff = 4; break;
    }
    console.log(quantite);

    var Coeur = (function() {
        var flakes;
        var flakesTotal = quantite;
        var wind = ventCoeff;
        var mouseX = 0;
        var mouseY = 0;

       function Coeur(size, x, y, vx, vy) {
    this.size = size;
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.hit = false;
    this.melt = false;
    this.div = document.createElement('div');
    this.div.classList.add('Coeur');
    this.div.style.width = this.size + 'px';
    this.div.style.height = this.size + 'px';
    this.div.style.position = 'fixed';
    this.div.style.top = '0';
    this.div.style.left = '0';
    this.div.style.pointerEvents = 'none';
    this.div.style.zIndex = '9999';
    this.div.style.background = 'none';
    this.div.style.fontSize = this.size + 'px';
    this.div.style.color = '#e91e63';
    this.div.style.opacity = '0.9';
}

        Coeur.prototype.move = function() {
            if (this.hit) {
                if (Math.random() > 0.995) this.melt = true;
            } else {
                this.x += this.vx + Math.min(Math.max(wind, -10), 10);
                this.y += this.vy;
            }
            if (this.x > window.innerWidth) {
                this.x = 0;
            }
            if (this.x < 0) {
                this.x = window.innerWidth;
            }

            if (this.y > window.innerHeight + this.size) {
                this.x = Math.random() * window.innerWidth;
                this.y = -this.size;
                this.melt = false;
            }
            var dx = mouseX - this.x;
            var dy = mouseY - this.y;
            this.hit = !this.melt && this.y < mouseY && dx * dx + dy * dy < 2400;
        };

        Coeur.prototype.draw = function() {
            this.div.style.transform =
            this.div.style.MozTransform =
            this.div.style.webkitTransform =
                'translate3d(' + this.x + 'px,' + this.y + 'px,0)';
        };

        function update() {
            for (var i = flakes.length; i--;) {
                var flake = flakes[i];
                flake.move();
                flake.draw();
            }
            requestAnimationFrame(update);
        }

        Coeur.init = function(container) {
            flakes = [];
            for (var i = flakesTotal; i--;) {
                var size = (Math.random() + 0.2) * tailleCoeff + 1;
                var flake = new Coeur(
                    size,
                    Math.random() * window.innerWidth,
                    Math.random() * window.innerHeight,
                    Math.random() - 0.5,
                    size * vitesseCoeff
                );
                container.appendChild(flake.div);
                flakes.push(flake);
            }
            window.ondeviceorientation = function(event) {
                if (event) {
                    wind = event.gamma / 10;
                }
            };
            update();
        };

        return Coeur;
    }());
    // if(activation === "on"){
         Coeur.init(document.body);
    // }
});
