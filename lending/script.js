document.documentElement.classList.add('js');

const menuButton = document.querySelector('.menu-button');
const siteNav = document.querySelector('.site-nav');
const header = document.querySelector('[data-header]');

function closeMenu() {
  if (!menuButton || !siteNav) return;
  menuButton.setAttribute('aria-expanded', 'false');
  siteNav.classList.remove('is-open');
}

if (menuButton && siteNav) {
  menuButton.addEventListener('click', () => {
    const isOpen = menuButton.getAttribute('aria-expanded') === 'true';
    menuButton.setAttribute('aria-expanded', String(!isOpen));
    siteNav.classList.toggle('is-open', !isOpen);
  });

  siteNav.querySelectorAll('a').forEach((link) => link.addEventListener('click', closeMenu));

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
      closeMenu();
      menuButton.focus();
    }
  });

  document.addEventListener('click', (event) => {
    if (!siteNav.contains(event.target) && !menuButton.contains(event.target)) closeMenu();
  });
}

function updateHeader() {
  if (header) header.classList.toggle('is-scrolled', window.scrollY > 16);
}

updateHeader();
window.addEventListener('scroll', updateHeader, { passive: true });

const planData = {
  oil: {
    kicker: 'СКОРО ПО ПРОБЕГУ',
    title: 'Моторное масло и фильтр',
    distance: '1 180 км',
    priority: 'Высокая',
    marker: 'Замена масла',
    markerDistance: '56 000 км',
    copy: 'Интервал рассчитан по регламенту и истории автомобиля. После выполнения сохраните работу и фактический пробег.',
  },
  brakes: {
    kicker: 'КОНТРОЛЬ СОСТОЯНИЯ',
    title: 'Тормозная система',
    distance: '3 400 км',
    priority: 'Высокая',
    marker: 'Осмотр тормозов',
    markerDistance: '58 200 км',
    copy: 'План напоминает об осмотре колодок, дисков и жидкости. При изменении торможения проверку нельзя откладывать до планового срока.',
  },
  filters: {
    kicker: 'ПЛАНОВАЯ ЗАМЕНА',
    title: 'Воздушный и салонный фильтры',
    distance: '5 180 км',
    priority: 'Средняя',
    marker: 'Замена фильтров',
    markerDistance: '60 000 км',
    copy: 'Срок основан на регламенте. Фактическое состояние зависит от условий эксплуатации и подтверждается при осмотре.',
  },
  fluids: {
    kicker: 'ПРОВЕРКА ПО СРОКУ',
    title: 'Технические жидкости',
    distance: '8 месяцев',
    priority: 'Средняя',
    marker: 'Контроль жидкостей',
    markerDistance: '02 / 2027',
    copy: 'AutoDoctor разделяет интервалы по пробегу и календарному сроку, чтобы важная проверка не потерялась при небольшом годовом пробеге.',
  },
};

const planFields = {
  kicker: document.querySelector('[data-plan-kicker]'),
  title: document.querySelector('[data-plan-title]'),
  distance: document.querySelector('[data-plan-distance]'),
  priority: document.querySelector('[data-plan-priority]'),
  copy: document.querySelector('[data-plan-copy]'),
  marker: document.querySelector('[data-plan-marker]'),
};

document.querySelectorAll('.consumable').forEach((button) => {
  button.addEventListener('click', () => {
    const data = planData[button.dataset.item];
    if (!data) return;

    document.querySelectorAll('.consumable').forEach((item) => {
      const isCurrent = item === button;
      item.classList.toggle('is-active', isCurrent);
      item.setAttribute('aria-pressed', String(isCurrent));
    });

    planFields.kicker.textContent = data.kicker;
    planFields.title.textContent = data.title;
    planFields.distance.textContent = data.distance;
    planFields.priority.textContent = data.priority;
    planFields.copy.textContent = data.copy;
    planFields.marker.innerHTML = `${data.marker}<br><small>${data.markerDistance}</small>`;
  });
});

document.querySelectorAll('.faq-item button').forEach((button) => {
  button.addEventListener('click', () => {
    const panel = document.getElementById(button.getAttribute('aria-controls'));
    const willOpen = button.getAttribute('aria-expanded') !== 'true';

    document.querySelectorAll('.faq-item button').forEach((otherButton) => {
      const otherPanel = document.getElementById(otherButton.getAttribute('aria-controls'));
      otherButton.setAttribute('aria-expanded', 'false');
      if (otherPanel) otherPanel.hidden = true;
    });

    button.setAttribute('aria-expanded', String(willOpen));
    if (panel) panel.hidden = !willOpen;
  });
});

const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const revealItems = document.querySelectorAll('.reveal');

if (reducedMotion || !('IntersectionObserver' in window)) {
  revealItems.forEach((item) => item.classList.add('is-visible'));
} else {
  const revealObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12, rootMargin: '0px 0px -40px' });

  revealItems.forEach((item) => revealObserver.observe(item));
}

const form = document.querySelector('.pilot-form');

if (form) {
  const email = form.querySelector('#email');
  const car = form.querySelector('#car');
  const message = form.querySelector('#message');
  const consent = form.querySelector('#consent');
  const emailError = form.querySelector('#email-error');
  const consentError = form.querySelector('#consent-error');
  const status = form.querySelector('.form-status');

  function showEmailError(text) {
    emailError.textContent = text;
    email.setAttribute('aria-invalid', String(Boolean(text)));
    if (text) email.setAttribute('aria-describedby', 'email-error');
    else email.removeAttribute('aria-describedby');
  }

  function validateEmail() {
    if (!email.value.trim()) {
      showEmailError('Укажите email для обратной связи.');
      return false;
    }
    if (!email.validity.valid) {
      showEmailError('Проверьте формат email.');
      return false;
    }
    showEmailError('');
    return true;
  }

  email.addEventListener('input', () => {
    if (email.getAttribute('aria-invalid') === 'true') validateEmail();
  });

  consent.addEventListener('change', () => {
    if (consent.checked) consentError.textContent = '';
  });

  form.addEventListener('submit', (event) => {
    event.preventDefault();
    status.textContent = '';

    const isEmailValid = validateEmail();
    const isConsentValid = consent.checked;
    consentError.textContent = isConsentValid ? '' : 'Подтвердите согласие для подготовки заявки.';

    if (!isEmailValid || !isConsentValid) {
      status.textContent = 'Проверьте обязательные поля.';
      status.style.color = 'var(--danger)';
      (isEmailValid ? consent : email).focus();
      return;
    }

    const subject = 'Заявка в закрытый пилот AutoDoctor';
    const body = [
      'Здравствуйте!',
      '',
      'Хочу подать заявку в закрытый пилот AutoDoctor.',
      '',
      `Email: ${email.value.trim()}`,
      `Автомобиль: ${car.value.trim() || 'не указан'}`,
      `Комментарий: ${message.value.trim() || 'нет'}`,
      '',
      'Согласие на обработку данных для заявки: да.',
    ].join('\n');

    status.style.color = 'var(--safe)';
    status.textContent = 'Открываем почтовое приложение. Проверьте письмо и отправьте его самостоятельно.';
    window.location.href = `mailto:pilot@autodoctor.by?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
  });
}

const year = document.querySelector('[data-year]');
if (year) year.textContent = new Date().getFullYear();
