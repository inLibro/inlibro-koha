document.addEventListener('DOMContentLoaded', function() {

    var options = window.HalloweenThemeOptions || {};
    var activation = options.activation_spiders || "on";
    var quantite = parseInt(options.quantite_spiders) || 2;
    var ghostEnabled = options.activation_ghost || "on";
    var navbarCollapse = document.querySelector('nav.breadcrumbs');
    const footer = document.querySelector('footer#changelanguage .collapse.navbar-collapse');

  // 
  // SECTION : arraigner, animation dans le navbar
  // 
  if (navbarCollapse && activation=== 'on') {
    const numberOfSpiders = quantite; 
    const totalWidthPercent = 60; 
    const startPercent = 50 - totalWidthPercent / 2; 

    for (let i = 0; i < numberOfSpiders; i++) {
      const spider = document.createElement('div');
      spider.className = `spider spider_${i}`;

      const eyeLeft = document.createElement('div');
      eyeLeft.className = 'eye left';

      const eyeRight = document.createElement('div');
      eyeRight.className = 'eye right';

      spider.appendChild(eyeLeft);
      spider.appendChild(eyeRight);

      // 4 legs left
      for (let j = 0; j < 4; j++) {
        const leg = document.createElement('span');
        leg.className = 'leg left';
        leg.style.top = `${20 + j * 5}px`;
        const leftOffset = -8 + j * 1.5;
        leg.style.left = `${leftOffset}px`;
        spider.appendChild(leg);
      }

      // 4 legs right
      for (let j = 0; j < 4; j++) {
        const leg = document.createElement('span');
        leg.className = 'leg right';
        leg.style.top = `${20 + j * 5}px`;
        const rightOffset = -8 + j * 1.5;
        leg.style.right = `${rightOffset}px`;
        spider.appendChild(leg);
      }
      // Calcul de la position horizontale en %
      let leftPercent;
      if (numberOfSpiders === 1) {
        leftPercent = 50; // centre si une seule araignée
      } else {
        leftPercent = startPercent + (totalWidthPercent / (numberOfSpiders - 1)) * i;
      }
      spider.style.position = 'absolute';
      spider.style.top = '0'; 
      spider.style.left = `${leftPercent}%`;
      navbarCollapse.appendChild(spider);
    }
  }

  //
  //  SECTION : Ghost,  suivie du curseur
  //
   if (ghostEnabled === 'on' && window.innerWidth > 768) {
       const ghostHtml = `
        <div id="ghost" class="ghost">
            <div class="ghost__head">
                <div class="ghost__eyes"></div>
                <div class="ghost__mouth"></div>
            </div>
            <div class="ghost__tail">
                <div class="ghost__rip"></div>
            </div>
        </div>
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1" id="ghost-filter"
            style="position: absolute; width: 0; height: 0; overflow: hidden; z-index: -1; pointer-events: none;">
            <defs>
                <filter id="goo">
                    <feGaussianBlur in="SourceGraphic" stdDeviation="10" result="ghost-blur" />
                    <feColorMatrix in="ghost-blur" mode="matrix"
                        values="1 0 0 0 0
                                0 1 0 0 0
                                0 0 1 0 0
                                0 0 0 16 -7"
                        result="ghost-gooey" />
                </filter>
            </defs>
        </svg>
      `;
        document.body.insertAdjacentHTML('beforeend', ghostHtml);
        loadGhostCursor();
    }

    function loadGhostCursor() {
        let mouse = { x: window.innerWidth / 2, y: window.innerHeight / 2, dir: '' };
        let clicked = false;

          const getMouse = (e) => {
            const clientX = e.clientX || e.pageX || e.touches?.[0]?.pageX || window.innerWidth / 2;
            const clientY = e.clientY || e.pageY || e.touches?.[0]?.pageY || window.innerHeight / 2;

            mouse = {
                x: clientX,
                y: clientY + window.scrollY, 
                dir: (getMouse.x > clientX) ? 'left' : 'right'
            };
        };
        ['mousemove', 'touchstart', 'touchmove'].forEach(e => {
            window.addEventListener(e, getMouse);
        });
        window.addEventListener('mousedown', (e) => {
            // e.preventDefault();
            clicked = true;
        });
        window.addEventListener('mouseup', () => {
            clicked = false;
        });

        class GhostFollow {
            constructor(options) {
                Object.assign(this, options);
                this.el = document.querySelector('#ghost');
                this.mouth = document.querySelector('.ghost__mouth');
                this.eyes = document.querySelector('.ghost__eyes');
                this.pos = { x: 0, y: 0 };
            }

            follow() {
                this.distX = mouse.x - this.pos.x;
                this.distY = mouse.y - this.pos.y;

                this.velX = this.distX / 8;
                this.velY = this.distY / 8;

                this.pos.x += this.distX / 10;
                this.pos.y += this.distY / 10;

                this.skewX = map(this.velX, 0, 100, 0, -50);
                this.scaleY = map(this.velY, 0, 100, 1, 2.0);
                this.scaleEyeX = map(Math.abs(this.velX), 0, 100, 1, 1.2);
                this.scaleEyeY = map(Math.abs(this.velX * 2), 0, 100, 1, 0.1);
                this.scaleMouth = Math.min(
                    Math.max(map(Math.abs(this.velX * 1.5), 0, 100, 0, 10),
                    map(Math.abs(this.velY * 1.2), 0, 100, 0, 5)),
                    2
                );

                if (clicked) {
                    this.scaleEyeY = 0.4;
                    this.scaleMouth = -this.scaleMouth;
                }

                this.el.style.transform = `translate(${this.pos.x}px, ${this.pos.y}px) scale(.7) skew(${this.skewX}deg) rotate(${-this.skewX}deg) scaleY(${this.scaleY})`;
                this.eyes.style.transform = `translateX(-50%) scale(${this.scaleEyeX}, ${this.scaleEyeY})`;
                this.mouth.style.transform = `translate(${(-this.skewX * 0.5 - 10)}px) scale(${this.scaleMouth})`;
            }
        }

        function map(num, in_min, in_max, out_min, out_max) {
            return (num - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
        }

        const ghostCursor = new GhostFollow();

        const render = () => {
            requestAnimationFrame(render);
            ghostCursor.follow();
        };
        render();
    }

  // 
  // SECTION : witch brew pour footer
  // 
  if (footer) {
    const witchBrewHTML = `
      <div id="witch-brew">
         <svg viewBox="0 0 308 383" style="enable-background:new 0 0 308 383;">
          <g id="bubble-blue-small">
            <circle style="fill:#5E5C93;" cx="181" cy="21" r="5"/>
          </g>
          <g id="bubble-red">
            <circle style="fill:#E05F5F;" cx="194" cy="67" r="20"/>
          </g>
          <g id="bubble-blue">
            <circle style="fill:#5E5C93;" cx="154" cy="47" r="11"/>
          </g>
          <g id="bubble-green-small">
            <circle style="fill:#8FE5A5;" cx="133" cy="21" r="5"/>
          </g>
          <g id="bubble-red-small">
            <circle style="fill:#E05F5F;" cx="108" cy="21" r="5"/>
          </g>
          <g id="bubbles-blue">
            <circle id="blue_2_" style="fill:#5E5C93;" cx="128" cy="136" r="29"/>
          </g>
          <g id="bubble-green">
            <circle style="fill:#8FE5A5;" cx="97" cy="62" r="15"/>
          </g>
          <g id="bubbles-green">
            <circle id="green-b_1_" style="fill:#8FE5A5;" cx="119" cy="148" r="34"/>
            <circle id="green-a_1_" style="fill:#8FE5A5;" cx="78" cy="141" r="18"/>
          </g>
          <g id="bubbles-red">
            <circle id="red-b" style="fill:#E05F5F;" cx="168" cy="141" r="40"/>
            <circle id="red-a" style="fill:#E05F5F;" cx="208.5" cy="142.5" r="31.5"/>
          </g>
          <g id="pot">
            <path style="fill:#2B2B2B;" d="M275.5,264.1c-2.6,10.1-6.9,19.7-12.5,28.5c0.2,0,0.3,0,0.5-0.1c0.6,4.8,1.2,9.7,1.8,14.5
              c1,8.3,2.1,16.6,3.1,24.9c0.7,5.7,2.6,12.3-1.9,16.9c-4.4,4.5-11.9,4.1-15.8-0.9c-1.2-1.6-1.6-3.2-2.2-5c-0.4-1.1-0.8-2.1-1.2-3.2
              c-2.6-6.8-5.2-13.5-7.8-20.3c-0.1-0.2-0.1-0.3-0.2-0.5c-2.2,1.8-4.4,3.5-6.8,5.1c-1.1,0.8-2.2,1.5-3.4,2.3c-0.5,0.3-1,0.7-1.5,1
              c-0.3,0.2-1.5,0.7-1.6,1c-0.1,0.4,0.2,1.3,0.3,1.7c0.2,1.3,0.4,2.5,0.6,3.8c0.4,2.7,0.8,5.3,1.3,8c0.1,0.5,0.2,1.1,0.2,1.6
              c0.1,2-1.2,4.1-2.7,5.3c-3.6,2.7-8.6,1.4-10.5-2.6c-0.9-1.9-1.9-3.8-2.9-5.7c-0.6-1.1-1.1-2.2-1.7-3.3c0-0.1-0.2-0.5-0.3-0.6
              c-0.1-0.1-1.2,0.5-1.4,0.6c-0.8,0.4-1.6,0.7-2.5,1c-5.2,2.1-10.6,3.9-16.1,5.4c-21.7,5.8-44.7,6.4-66.7,1.8
              c-5.5-1.2-10.9-2.6-16.2-4.4c-2.6-0.9-5.2-1.9-7.8-2.9c-0.7-0.3-1.4-0.6-2-0.9c-0.2-0.1-1.2-0.7-1.4-0.6c-0.1,0.1-0.3,0.6-0.3,0.7
              c-1.2,2.3-2.4,4.7-3.5,7c-0.4,0.7-0.7,1.4-1,2.1c-0.9,1.9-2.7,3.3-4.8,3.7c-3.9,0.8-8.5-2.4-8.3-6.6c0.1-1.8,0.6-3.6,0.8-5.3
              c0.4-2.7,0.8-5.4,1.3-8.1c0.1-0.4,0.4-1.3,0.3-1.7c-0.1-0.3-1.1-0.7-1.4-0.9c-0.6-0.4-1.1-0.7-1.7-1.1c-1.2-0.8-2.5-1.6-3.7-2.5
              c-2.2-1.6-4.4-3.2-6.5-4.9c-2.3,6.1-4.7,12.2-7,18.3c-0.9,2.2-1.9,4.5-2.5,6.8c-1.5,6.1-8.3,9.5-14.1,7.1c-4.4-1.8-6.9-6.4-6.5-11
              c0.2-2,0.5-4,0.7-5.9c1-8.1,2-16.1,3-24.2c0.5-3.8,0.9-7.5,1.4-11.3c0.2-1.3,0.3-2.6,0.5-3.9c0.1-0.6,0-1.6,0.3-2.1
              c0-0.1,0-0.2,0-0.3c0.1,0,0.3,0,0.5,0.1c-7.6-11.9-12.6-25.3-14.5-39.3c-2-14.7-0.5-29.9,4.4-44c1.2-3.5,2.7-7,4.3-10.4
              c0.8-1.6,1.6-3.3,2.6-4.8c0.9-1.4,1.9-2.8,2.6-4.4c2.9-6.7,3.1-15.1,0.6-21.9c-1.1-3-2.8-5.7-5-7.9c-1.9-2-3.3-4.2-3.9-6.9
              c-1.2-5.3,1.1-11,5.6-14.1c3.2-2.2,6.9-2.4,10.6-2.4c2.9,0,5.9,0,8.8,0c4.7,0,9.5,0,14.2,0c6.2,0,12.4,0,18.6,0
              c7.2,0,14.4,0,21.6,0c7.8,0,15.7,0,23.5,0c8,0,16,0,24,0c7.9,0,15.7,0,23.6,0c7.3,0,14.5,0,21.8,0c6.2,0,12.5,0,18.7,0
              c4.9,0,9.7,0,14.6,0c3.1,0,6.1,0,9.2,0c3.1,0,6.2-0.2,9.2,0c5.6,0.3,10.5,3.1,12.6,8.5c2,5,0.8,10.6-2.9,14.4
              c-2.5,2.6-4.3,5.2-5.5,8.6c-1.2,3.4-1.6,7.1-1.5,10.7c0.1,3.5,0.7,6.9,1.9,10.2c1.3,3.3,3.5,6,5,9.1c6.8,13.6,10.3,28.8,10,44
              C278.4,249.5,277.4,256.9,275.5,264.1z"/>
          </g>
          <g id="spillover">
            <path id="a-long_2_" style="fill:#8FE5A5;" d="M118,162L118,162c-5.5,0-10-4.5-10-10v-15c0-5.5,4.5-10,10-10h0c5.5,0,10,4.5,10,10
              v15C128,157.5,123.5,162,118,162z"/>
            <path id="b-long_2_" style="fill:#E05F5F;" d="M201,163L201,163c-5.5,0-10-4.5-10-10v-17c0-5.5,4.5-10,10-10h0c5.5,0,10,4.5,10,10
              v17C211,158.5,206.5,163,201,163z"/>
          </g>
          <g id="drip-red">
            <path id="b-long_5_" style="fill:#E05F5F;" d="M201,162L201,162c-5.5,0-10-4.5-10-10v-6c0-5.5,4.5-10,10-10h0c5.5,0,10,4.5,10,10v6
              C211,157.5,206.5,162,201,162z"/>
          </g>
          <g id="drip-green">
            <path id="b-long_3_" style="fill:#8FE5A5;" d="M118,162L118,162c-5.5,0-10-4.5-10-10v-6c0-5.5,4.5-10,10-10h0c5.5,0,10,4.5,10,10v6
              C128,157.5,123.5,162,118,162z"/>
          </g>
          </svg>
      </div>
    `;

    footer.insertAdjacentHTML('beforeend', witchBrewHTML);
  }
  function setupBubbleAnimations() {
    const blueBubbles = document.querySelector('#bubbles-blue');
    const greenBubbles = document.querySelector('#bubbles-green');
    const redBubbles = document.querySelector('#bubbles-red');
    const blueBubble = document.querySelector('#bubble-blue');
    const redBubble = document.querySelector('#bubble-red');
    const greenBubble = document.querySelector('#bubble-green');
    const blueBubbleSmall = document.querySelector('#bubble-blue-small');
    const redBubbleSmall = document.querySelector('#bubble-red-small');
    const greenBubbleSmall = document.querySelector('#bubble-green-small');
    const dripRed = document.querySelector('#drip-red');
    const dripGreen = document.querySelector('#drip-green');

    if (!blueBubble || !redBubble || !greenBubble) return;

    // Ajouter classes pour animer les bulles
    blueBubble.classList.add('bubble', 'bubble--blue');
    greenBubble.classList.add('bubble', 'bubble--green');
    redBubble.classList.add('bubble', 'bubble--red');

    blueBubbleSmall.classList.add('bubble', 'bubble--blue', 'bubble--small');
    greenBubbleSmall.classList.add('bubble', 'bubble--green', 'bubble--small');
    redBubbleSmall.classList.add('bubble', 'bubble--red', 'bubble--small');

    // Ajouter classe pour faire flotter les groupes de bulles
    blueBubbles?.classList.add('bubble-group');
    greenBubbles?.classList.add('bubble-group');
    redBubbles?.classList.add('bubble-group');

    // Ajouter classes d’animation pour les gouttes
    dripRed?.classList.add('drip', 'drip--red');
    dripGreen?.classList.add('drip', 'drip--green');
  }
  setupBubbleAnimations();

  // 
  // SECTION : citrouillew, pour le footer
  // 
  function getPumpkinHTML(id) {
    return `
      <div class="container" id="${id}">
        <div class="stem-container">
          <div class="stem"></div>
        </div>
        <div class="slice one"></div>
        <div class="slice two"></div>
        <div class="slice tree"></div>
        <div class="slice four"></div>
        <div class="slice five"></div>
        <div class="eyes">
          <div class="eye left-eye"></div>
          <div class="eye right-eye"></div>
        </div>
        <div class="nose"></div>
        <div class="mouth">
          <div class="tooth"></div>
          <div class="tooth tooth2"></div>
          <div class="tooth tooth3"></div>
          <div class="tooth tooth4"></div>
          <div class="tooth tooth5"></div>
        </div>
      </div>
    `;
  }
  if (footer) {
    footer.insertAdjacentHTML('beforeend', getPumpkinHTML('pumpkin-left'));
    footer.insertAdjacentHTML('beforeend', getPumpkinHTML('pumpkin-right'));
  }
});
