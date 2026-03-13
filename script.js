// TechSupport Pro - Dashboard JavaScript

// DOM Elements
const modal = document.getElementById('resultModal');
const modalTitle = document.getElementById('modalTitle');
const modalResult = document.getElementById('modalResult');
const confirmModal = document.getElementById('confirmModal');
const confirmTitle = document.getElementById('confirmTitle');
const confirmMessage = document.getElementById('confirmMessage');
const confirmBtn = document.getElementById('confirmBtn');
const loadingOverlay = document.getElementById('loadingOverlay');
const loadingText = document.getElementById('loadingText');
const toast = document.getElementById('toast');
const categoryTabs = document.querySelectorAll('.category-tab');
const commandsGrids = document.querySelectorAll('.commands-grid');
const navLinks = document.querySelectorAll('.nav-link');
const contentSections = document.querySelectorAll('.content-section');
const searchInput = document.getElementById('searchInputHeader');

// API Base URL
const API_URL = '/api';

// State
let isAdmin = false;
let history = JSON.parse(localStorage.getItem('techsupport_history') || '[]');
let backups = JSON.parse(localStorage.getItem('techsupport_backups') || '[]');
let currentConfirmAction = null;

// Profiles
const profiles = {
    quickClean: ['cleanTemp', 'cleanRecycleBin', 'flushDNS'],
    fullClean: ['cleanTemp', 'cleanWindowsTemp', 'cleanPrefetch', 'cleanRecycleBin', 'cleanBrowserCache', 'flushDNS'],
    networkFix: ['flushDNS', 'resetWinsock', 'releaseRenewIP', 'resetNetwork']
};

// Command info for display
const commandInfo = {
    cleanTemp: { name: 'Очистка папки TEMP', category: 'cleaning' },
    cleanWindowsTemp: { name: 'Очистка Windows Temp', category: 'cleaning' },
    cleanPrefetch: { name: 'Очистка Prefetch', category: 'cleaning' },
    cleanRecycleBin: { name: 'Очистка корзины', category: 'cleaning' },
    cleanBrowserCache: { name: 'Очистка кэша браузеров', category: 'cleaning' },
    cleanWindowsUpdate: { name: 'Очистка обновлений Windows', category: 'cleaning' },
    flushDNS: { name: 'Сброс DNS кэша', category: 'network' },
    releaseRenewIP: { name: 'Обновление IP-адреса', category: 'network' },
    resetNetwork: { name: 'Полный сброс сети', category: 'network' },
    showNetworkInfo: { name: 'Информация о сети', category: 'network' },
    pingGoogle: { name: 'Проверка соединения', category: 'network' },
    resetWinsock: { name: 'Сброс Winsock', category: 'network' },
    systemInfo: { name: 'Информация о системе', category: 'system' },
    checkDisk: { name: 'Проверка диска (CHKDSK)', category: 'system' },
    sfcScan: { name: 'Проверка системных файлов (SFC)', category: 'system' },
    diskCleanup: { name: 'Очистка диска', category: 'system' },
    defragDisk: { name: 'Дефрагментация / Оптимизация', category: 'system' },
    listProcesses: { name: 'Список процессов', category: 'system' },
    firewallStatus: { name: 'Статус брандмауэра', category: 'security' },
    windowsDefender: { name: 'Windows Defender', category: 'security' },
    quickScan: { name: 'Быстрое сканирование', category: 'security' },
    updateDefender: { name: 'Обновление сигнатур Defender', category: 'security' },
    showOpenPorts: { name: 'Открытые порты', category: 'security' },
    securityAudit: { name: 'Аудит безопасности', category: 'security' },
    diskHealth: { name: 'Здоровье диска (S.M.A.R.T.)', category: 'diagnostics' },
    batteryReport: { name: 'Отчёт о батарее', category: 'diagnostics' },
    eventViewer: { name: 'Просмотр событий', category: 'diagnostics' },
    driverQuery: { name: 'Список драйверов', category: 'diagnostics' },
    memoryDiagnostics: { name: 'Диагностика памяти', category: 'diagnostics' },
    performanceReport: { name: 'Отчёт производительности', category: 'diagnostics' },
    openTaskManager: { name: 'Диспетчер задач', category: 'tools' },
    openDeviceManager: { name: 'Диспетчер устройств', category: 'tools' },
    openControlPanel: { name: 'Панель управления', category: 'tools' },
    openMsConfig: { name: 'Конфигурация системы (MSConfig)', category: 'tools' },
    openRegistry: { name: 'Редактор реестра', category: 'tools' },
    openPowerShell: { name: 'PowerShell', category: 'tools' },
    whoIsConnected: { name: 'Кто подключён', category: 'info' },
    installedPrograms: { name: 'Установленные программы', category: 'info' },
    startupPrograms: { name: 'Программы в автозагрузке', category: 'info' },
    networkConnections: { name: 'Активные соединения', category: 'info' },
    servicesList: { name: 'Службы Windows', category: 'info' },
    systemUptime: { name: 'Время работы системы', category: 'info' },
    userInfo: { name: 'Информация о пользователе', category: 'info' },
    windowsStatus: { name: 'Статус активации Windows', category: 'info' },
    speedTest: { name: 'Тест скорости интернета', category: 'info' },
    windowsUpdates: { name: 'Установленные обновления', category: 'info' },
    recentFiles: { name: 'Недавние файлы', category: 'info' },
    clearClipboard: { name: 'Очистить буфер обмена', category: 'info' },
    fullDiagnostic: { name: 'Полная диагностика', category: 'quick' },
    quickFix: { name: 'Быстрое исправление', category: 'quick' },
    optimizeSystem: { name: 'Оптимизация', category: 'quick' }
};

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    initNavigation();
    initCategoryTabs();
    initSearch();
    checkAdminStatus();
    refreshSystemInfo();
    updateHistoryUI();
    updateBackupsUI();
    generateRecommendations();
    
    // Refresh system info periodically
    setInterval(refreshSystemInfo, 30000);
});

// Navigation
function initNavigation() {
    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const section = link.dataset.section;
            
            // Update active nav link
            navLinks.forEach(l => l.classList.remove('active'));
            link.classList.add('active');
            
            // Show corresponding section
            contentSections.forEach(s => s.classList.remove('active'));
            document.getElementById(section).classList.add('active');
            
            // Scroll to content
            document.querySelector('.main-content').scrollIntoView({ behavior: 'smooth' });
        });
    });
    
    // Header scroll indicator
    const scrollIndicator = document.querySelector('.header-scroll-indicator');
    if (scrollIndicator) {
        scrollIndicator.addEventListener('click', () => {
            document.querySelector('.main-content').scrollIntoView({ behavior: 'smooth' });
        });
    }
}

// Category Tabs
function initCategoryTabs() {
    categoryTabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const category = tab.dataset.category;
            
            // Update active tab
            categoryTabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            
            // Show corresponding grid
            commandsGrids.forEach(grid => {
                grid.classList.remove('active');
                if (grid.id === category) {
                    grid.classList.add('active');
                }
            });
        });
    });
}

// Search
function initSearch() {
    if (searchInput) {
        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase();
            
            if (query.length > 0) {
                // Show all grids for search
                commandsGrids.forEach(grid => grid.classList.add('active'));
                
                const commandCards = document.querySelectorAll('.command-card');
                commandCards.forEach(card => {
                    const text = card.textContent.toLowerCase();
                    card.style.display = text.includes(query) ? '' : 'none';
                });
            } else {
                // Reset to active tab only
                const commandCards = document.querySelectorAll('.command-card');
                commandCards.forEach(card => card.style.display = '');
                
                const activeTab = document.querySelector('.category-tab.active');
                if (activeTab) {
                    const category = activeTab.dataset.category;
                    commandsGrids.forEach(grid => {
                        grid.classList.toggle('active', grid.id === category);
                    });
                }
            }
        });
    }
}

// Check Admin Status
async function checkAdminStatus() {
    try {
        const response = await fetch(`${API_URL}/admin-check`);
        const data = await response.json();
        
        isAdmin = data.isAdmin;
        updateAdminUI();
    } catch (error) {
        console.error('Failed to check admin status:', error);
        isAdmin = false;
        updateAdminUI();
    }
}

// Update Admin UI
function updateAdminUI() {
    const adminStatusHeader = document.getElementById('adminStatusHeader');
    const adminBanner = document.getElementById('adminBanner');
    
    if (adminStatusHeader) {
        const indicator = adminStatusHeader.querySelector('.status-dot');
        const statusText = adminStatusHeader.querySelector('span');
        
        if (isAdmin) {
            indicator.classList.remove('warning', 'error');
            indicator.classList.add('success');
            statusText.textContent = 'Права администратора';
            if (adminBanner) adminBanner.style.display = 'none';
        } else {
            indicator.classList.remove('success');
            indicator.classList.add('warning');
            statusText.textContent = 'Ограниченные права';
            if (adminBanner) adminBanner.style.display = 'flex';
        }
    }
}

// Execute Command
async function executeCommand(command) {
    showLoading('Выполнение команды...');
    
    try {
        const response = await fetch(`${API_URL}/execute`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ command })
        });
        
        const data = await response.json();
        
        hideLoading();
        
        // Add to history
        addToHistory(command, data.success, data.result || data.error);
        
        if (data.success) {
            showModal(commandInfo[command]?.name || command, data.result);
            showToast('Команда выполнена успешно', 'success');
        } else {
            showModal('Ошибка', data.error || 'Неизвестная ошибка');
            showToast('Ошибка выполнения команды', 'error');
        }
    } catch (error) {
        hideLoading();
        showModal('Ошибка соединения', 'Не удалось подключиться к серверу. Убедитесь, что сервер запущен.');
        showToast('Ошибка соединения', 'error');
    }
}

// Refresh System Info
async function refreshSystemInfo() {
    try {
        const response = await fetch(`${API_URL}/system-info`);
        const data = await response.json();
        
        if (data.success) {
            // Update CPU
            const cpuInfo = document.getElementById('cpuInfo');
            const headerCpu = document.getElementById('headerCpu');
            if (cpuInfo) cpuInfo.textContent = data.cpu || 'Неизвестно';
            const cpuPercent = 30 + Math.random() * 40;
            animateBar('cpuBar', cpuPercent);
            if (headerCpu) headerCpu.textContent = Math.round(cpuPercent) + '%';
            
            // Update RAM
            const ramInfo = document.getElementById('ramInfo');
            const headerRam = document.getElementById('headerRam');
            if (ramInfo) ramInfo.textContent = data.ram || 'Неизвестно';
            const ramPercent = calculateRamPercentage(data.ram);
            animateBar('ramBar', ramPercent);
            if (headerRam) headerRam.textContent = Math.round(ramPercent) + '%';
            
            // Update Disk
            const diskInfo = document.getElementById('diskInfo');
            const headerDisk = document.getElementById('headerDisk');
            if (diskInfo) diskInfo.textContent = data.disk || 'Неизвестно';
            const diskPercent = calculateDiskPercentage(data.disk);
            animateBar('diskBar', diskPercent);
            if (headerDisk) headerDisk.textContent = Math.round(diskPercent) + '%';
            
            // Update OS
            const osInfo = document.getElementById('osInfo');
            if (osInfo) osInfo.textContent = data.os || 'Неизвестно';
        }
    } catch (error) {
        console.error('Failed to fetch system info:', error);
    }
}

// Calculate RAM percentage
function calculateRamPercentage(ramString) {
    if (!ramString) return 50;
    const match = ramString.match(/([\d.]+)\s*GB\s*\/\s*([\d.]+)\s*GB/);
    if (match) {
        const used = parseFloat(match[1]);
        const total = parseFloat(match[2]);
        return (used / total) * 100;
    }
    return 50;
}

// Calculate Disk percentage
function calculateDiskPercentage(diskString) {
    if (!diskString) return 60;
    const match = diskString.match(/([\d.]+)\s*GB\s*\/\s*([\d.]+)\s*GB/);
    if (match) {
        const free = parseFloat(match[1]);
        const total = parseFloat(match[2]);
        return ((total - free) / total) * 100;
    }
    return 60;
}

// Animate progress bar
function animateBar(barId, percentage) {
    const bar = document.getElementById(barId);
    if (bar) {
        bar.style.width = '0%';
        setTimeout(() => {
            bar.style.width = Math.min(percentage, 100) + '%';
        }, 100);
    }
}

// Generate Recommendations
async function generateRecommendations() {
    const container = document.getElementById('recommendations');
    
    try {
        const response = await fetch(`${API_URL}/system-info`);
        const data = await response.json();
        
        const recommendations = [];
        
        // Check disk space
        const diskPercent = calculateDiskPercentage(data.disk);
        if (diskPercent > 80) {
            recommendations.push({
                type: 'warning',
                text: `Диск заполнен на ${Math.round(diskPercent)}%. Рекомендуется очистка.`,
                action: 'Очистить',
                command: 'optimizeSystem'
            });
        }
        
        // Check RAM
        const ramPercent = calculateRamPercentage(data.ram);
        if (ramPercent > 85) {
            recommendations.push({
                type: 'warning',
                text: 'Оперативная память почти заполнена. Проверьте процессы.',
                action: 'Процессы',
                command: 'listProcesses'
            });
        }
        
        // General recommendations
        if (recommendations.length === 0) {
            recommendations.push({
                type: 'success',
                text: 'Система работает нормально. Рекомендаций нет.',
                action: null
            });
        }
        
        // Render recommendations
        container.innerHTML = recommendations.map(rec => `
            <div class="recommendation ${rec.type}">
                <div class="rec-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        ${rec.type === 'warning' 
                            ? '<path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>'
                            : '<path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>'
                        }
                    </svg>
                </div>
                <div class="rec-content">
                    <span>${rec.text}</span>
                </div>
                ${rec.action ? `<button class="rec-action" onclick="executeCommand('${rec.command}')">${rec.action}</button>` : ''}
            </div>
        `).join('');
        
    } catch (error) {
        container.innerHTML = `
            <div class="recommendation">
                <div class="rec-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="12" y1="8" x2="12" y2="12"/>
                        <line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                </div>
                <div class="rec-content">
                    <span>Не удалось получить информацию о системе</span>
                </div>
            </div>
        `;
    }
}

// ==================== HISTORY ====================

function addToHistory(command, success, result) {
    const entry = {
        id: Date.now(),
        command: command,
        name: commandInfo[command]?.name || command,
        success: success,
        result: result,
        timestamp: new Date().toISOString()
    };
    
    history.unshift(entry);
    
    // Keep only last 50 entries
    if (history.length > 50) {
        history = history.slice(0, 50);
    }
    
    localStorage.setItem('techsupport_history', JSON.stringify(history));
    updateHistoryUI();
}

function updateHistoryUI() {
    const container = document.getElementById('historyList');
    const countBadge = document.getElementById('historyCountHeader');
    
    if (countBadge) countBadge.textContent = history.length;
    
    if (history.length === 0) {
        container.innerHTML = `
            <div class="history-empty">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"/>
                    <polyline points="12 6 12 12 16 14"/>
                </svg>
                <p>История пуста</p>
                <span>Выполненные команды появятся здесь</span>
            </div>
        `;
        return;
    }
    
    container.innerHTML = history.map(entry => `
        <div class="history-item">
            <div class="history-icon ${entry.success ? 'success' : 'error'}">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    ${entry.success 
                        ? '<polyline points="20 6 9 17 4 12"/>'
                        : '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>'
                    }
                </svg>
            </div>
            <div class="history-content">
                <div class="history-command">${entry.name}</div>
                <div class="history-time">${formatTime(entry.timestamp)}</div>
            </div>
            <div class="history-actions">
                <button class="history-btn" onclick="showHistoryResult(${entry.id})">Результат</button>
                <button class="history-btn" onclick="retryCommand('${entry.command}')">Повторить</button>
            </div>
        </div>
    `).join('');
}

function showHistoryResult(id) {
    const entry = history.find(e => e.id === id);
    if (entry) {
        showModal(entry.name, entry.result);
    }
}

function retryCommand(command) {
    executeCommand(command);
}

function clearHistory() {
    showConfirm('Очистить историю?', 'Вы уверены, что хотите очистить историю всех выполненных команд?', () => {
        history = [];
        localStorage.setItem('techsupport_history', JSON.stringify(history));
        updateHistoryUI();
        showToast('История очищена', 'success');
    });
}

// ==================== BACKUPS ====================

async function createBackup() {
    showLoading('Создание бэкапа...');
    
    try {
        const response = await fetch(`${API_URL}/backup/create`, {
            method: 'POST'
        });
        
        const data = await response.json();
        
        hideLoading();
        
        if (data.success) {
            const backup = {
                id: Date.now(),
                name: `Бэкап от ${formatDateTime(new Date())}`,
                timestamp: new Date().toISOString(),
                data: data.data
            };
            
            backups.unshift(backup);
            localStorage.setItem('techsupport_backups', JSON.stringify(backups));
            updateBackupsUI();
            
            showToast('Бэкап создан успешно', 'success');
        } else {
            showToast('Ошибка создания бэкапа: ' + data.error, 'error');
        }
    } catch (error) {
        hideLoading();
        showToast('Ошибка соединения', 'error');
    }
}

function updateBackupsUI() {
    const container = document.getElementById('backupsList');
    
    if (backups.length === 0) {
        container.innerHTML = `
            <div class="backups-empty">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/>
                    <polyline points="17 8 12 3 7 8"/>
                    <line x1="12" y1="3" x2="12" y2="15"/>
                </svg>
                <p>Нет бэкапов</p>
                <span>Создайте первый бэкап для защиты системы</span>
            </div>
        `;
        return;
    }
    
    container.innerHTML = backups.map(backup => `
        <div class="backup-item">
            <div class="backup-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/>
                    <polyline points="17 8 12 3 7 8"/>
                    <line x1="12" y1="3" x2="12" y2="15"/>
                </svg>
            </div>
            <div class="backup-content">
                <div class="backup-name">${backup.name}</div>
                <div class="backup-meta">${formatDateTime(new Date(backup.timestamp))}</div>
            </div>
            <div class="backup-actions">
                <button class="btn btn-secondary" onclick="viewBackup(${backup.id})">Просмотр</button>
                <button class="btn btn-primary" onclick="restoreBackup(${backup.id})">Восстановить</button>
                <button class="btn btn-secondary" onclick="deleteBackup(${backup.id})">Удалить</button>
            </div>
        </div>
    `).join('');
}

function viewBackup(id) {
    const backup = backups.find(b => b.id === id);
    if (backup) {
        showModal(backup.name, JSON.stringify(backup.data, null, 2));
    }
}

async function restoreBackup(id) {
    const backup = backups.find(b => b.id === id);
    if (!backup) return;
    
    showConfirm('Восстановить бэкап?', `Вы уверены, что хотите восстановить систему из бэкапа от ${formatDateTime(new Date(backup.timestamp))}?`, async () => {
        showLoading('Восстановление бэкапа...');
        
        try {
            const response = await fetch(`${API_URL}/backup/restore`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ data: backup.data })
            });
            
            const data = await response.json();
            
            hideLoading();
            
            if (data.success) {
                showModal('Восстановление завершено', data.result);
                showToast('Бэкап восстановлен', 'success');
            } else {
                showToast('Ошибка восстановления: ' + data.error, 'error');
            }
        } catch (error) {
            hideLoading();
            showToast('Ошибка соединения', 'error');
        }
    });
}

function deleteBackup(id) {
    showConfirm('Удалить бэкап?', 'Вы уверены, что хотите удалить этот бэкап?', () => {
        backups = backups.filter(b => b.id !== id);
        localStorage.setItem('techsupport_backups', JSON.stringify(backups));
        updateBackupsUI();
        showToast('Бэкап удалён', 'success');
    });
}

// ==================== PROFILES ====================

async function runProfile(profileId) {
    const commands = profiles[profileId];
    if (!commands) {
        showToast('Профиль не найден', 'error');
        return;
    }
    
    const profileNames = {
        quickClean: 'Быстрая очистка',
        fullClean: 'Полная очистка',
        networkFix: 'Исправление сети'
    };
    
    showConfirm(
        'Запустить профиль?',
        `Профиль "${profileNames[profileId]}" выполнит ${commands.length} команд. Продолжить?`,
        async () => {
            let results = [];
            
            for (const command of commands) {
                showLoading(`Выполнение: ${commandInfo[command]?.name || command}...`);
                
                try {
                    const response = await fetch(`${API_URL}/execute`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ command })
                    });
                    
                    const data = await response.json();
                    results.push({
                        command: commandInfo[command]?.name || command,
                        success: data.success,
                        result: data.success ? data.result : data.error
                    });
                    
                    addToHistory(command, data.success, data.result || data.error);
                } catch (error) {
                    results.push({
                        command: commandInfo[command]?.name || command,
                        success: false,
                        result: 'Ошибка соединения'
                    });
                }
            }
            
            hideLoading();
            
            // Show results
            const resultsText = results.map(r => 
                `${r.success ? '✓' : '✕'} ${r.command}: ${r.result?.substring(0, 100)}...`
            ).join('\n');
            
            showModal(`Профиль "${profileNames[profileId]}" выполнен`, resultsText);
            showToast('Профиль выполнен', 'success');
        }
    );
}

function showCreateProfile() {
    showToast('Функция в разработке', 'info');
}

// ==================== REPORTS ====================

async function exportReport() {
    showLoading('Создание отчёта...');
    
    try {
        const response = await fetch(`${API_URL}/system-info`);
        const data = await response.json();
        
        if (data.success) {
            const report = {
                timestamp: new Date().toISOString(),
                system: {
                    cpu: data.cpu,
                    ram: data.ram,
                    disk: data.disk,
                    os: data.os
                },
                history: history.slice(0, 10)
            };
            
            const blob = new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `techsupport-report-${formatDateForFile(new Date())}.json`;
            a.click();
            URL.revokeObjectURL(url);
            
            hideLoading();
            showToast('Отчёт экспортирован', 'success');
        }
    } catch (error) {
        hideLoading();
        showToast('Ошибка экспорта', 'error');
    }
}

function compareStates() {
    showToast('Функция в разработке', 'info');
}

// ==================== MODALS ====================

function showModal(title, content) {
    modalTitle.textContent = title;
    modalResult.textContent = content;
    modal.classList.add('active');
}

function closeModal() {
    modal.classList.remove('active');
}

function showConfirm(title, message, callback) {
    confirmTitle.textContent = title;
    confirmMessage.textContent = message;
    currentConfirmAction = callback;
    confirmModal.classList.add('active');
}

function closeConfirmModal() {
    confirmModal.classList.remove('active');
    currentConfirmAction = null;
}

function confirmAction() {
    if (currentConfirmAction) {
        currentConfirmAction();
    }
    closeConfirmModal();
}

// ==================== LOADING ====================

function showLoading(text = 'Загрузка...') {
    loadingText.textContent = text;
    loadingOverlay.classList.add('active');
}

function hideLoading() {
    loadingOverlay.classList.remove('active');
}

// ==================== TOAST ====================

function showToast(message, type = 'info') {
    toast.className = 'toast active ' + type;
    toast.querySelector('.toast-message').textContent = message;
    
    setTimeout(() => {
        toast.classList.remove('active');
    }, 3000);
}

function copyResult() {
    const text = modalResult.textContent;
    navigator.clipboard.writeText(text).then(() => {
        showToast('Скопировано в буфер', 'success');
    });
}

// ==================== HELPERS ====================

function formatTime(timestamp) {
    return new Date(timestamp).toLocaleTimeString('ru-RU', {
        hour: '2-digit',
        minute: '2-digit'
    });
}

function formatDateTime(date) {
    return date.toLocaleString('ru-RU', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function formatDateForFile(date) {
    return date.toISOString().slice(0, 10);
}

// Close modals on outside click
modal.addEventListener('click', (e) => {
    if (e.target === modal) {
        closeModal();
    }
});

confirmModal.addEventListener('click', (e) => {
    if (e.target === confirmModal) {
        closeConfirmModal();
    }
});

// Close modals on Escape key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (modal.classList.contains('active')) {
            closeModal();
        }
        if (confirmModal.classList.contains('active')) {
            closeConfirmModal();
        }
    }
});

// Console welcome message
console.log('%c TechSupport Pro ', 'background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; font-size: 20px; padding: 10px 20px; border-radius: 8px; font-weight: bold;');
console.log('%c Dashboard для технической поддержки Windows ', 'color: #94a3b8; font-size: 12px;');