 ## Стек                                                                     

  - Swift 6, строгая concurrency (@MainActor, actor, async/await)               
  - SwiftUI - весь UI
  - ApphudSDK - подписки и paywall                                              
  - URLSession - сетевой слой (без Alamofire)                                   
  - Keychain (Security framework) - хранение токенов                            
  - PhotosUI - выбор фото для видеогенерации                                    
  - StoreKit - запрос рейтинга через SKStoreReviewController                    
  - SPM - единственный менеджер зависимостей                                    
                                                                                
  ---                                                                           
                                         
  ## Архитектура                                                              
                                                                              
  MVVM по каждой фиче. Разбивка по модулям:                                     
   
  \```                                                                          
  Features/                  
    Home/           - главный экран, навигация
    AIChat/         - чат + история сессий                                      
    AIWriting/      - улучшение текста                                          
    VideoGenerator/ - генерация видео из фото                                   
    Paywall/        - экран подписки                                            
    Settings/       - настройки          
    Onboarding/     - онбординг                                                 
                                                                                
  Core/                                  
    DesignSystem/   - AppColors, AppFonts, переиспользуемые компоненты          
    Extensions/     - расширения View и др.                                     
                                         
  Network/                                                                      
    APIClient.swift - actor-based HTTP клиент
    APIConfig.swift - конфигурация, Secrets enum
    DTOs/           - Codable модели запросов/ответов                           
    KeychainHelper  - обёртка над Security API
                                                                                
  Services/                  
    ApphudService   - @MainActor singleton, подписки
  \```                                                                          
   
  ---                                                                           
                             
  ## Сетевой слой                        
                                                                              
  APIClient реализован как actor, потокобезопасный синглтон. Три группы методов:

  - Chat: POST /dola/chats/{id}/messages                                        
  - Writing: POST /ai-writing
  - Video: POST /pixverse/api/v1/template2video (multipart/form-data), polling  
  статуса через GET /pixverse/api/v1/status
                                         
  Multipart builder собирается вручную через Data.appendUTF8() без force unwrap,
   с пробросом ошибки.
                                                                                
  Все ошибки типизированы через APIError: LocalizedError (invalidURL,           
  invalidResponse(statusCode:), decodingError, networkError, unauthorized).
                                                                                
  ---                        
                                         
  ## Подписки (Apphud)                                                        

  ApphudService - @MainActor final class ObservableObject, синглтон.

  - fetchPaywallProducts() загружает продукты через Apphud.placement("main"),   
  конвертирует в PaywallProduct с расчётом недельной цены
  - purchase(_:) бриджит коллбэк Apphud в async throws через                    
  withCheckedThrowingContinuation                                               
  - restorePurchases() аналогично, resume прямо из коллбэка, 
  hasActiveSubscription обновляется после await                                 
  - В DEBUG билде hasActiveSubscription = true по умолчанию
                                         
  ---                                                                         
                                                                                
  ## Видеогенерация
                                                                                
  Флоу в VideoGeneratorViewModel:
                                         
  1. Пользователь выбирает шаблон + до 3 фото через PhotosPickerItem          
  2. generateVideo() отправляет JPEG через multipart на backend (Pixverse)
  3. Polling каждые 3 сек, максимум 40 попыток (2 минуты)                       
  4. При status == "completed" показывает плеер с кнопкой скачать в галерею
  5. Таймер (elapsedSeconds) идёт в отдельном Task, отменяется через nonisolated
   deinit                    
                                                                                
  ---                                                                         
                                         
  ## Хранение данных                                                          
                                                                                
  - Chat сессии: [ChatSession] сериализуется в JSON, пишется в 
  Documents/chat_sessions.json. Запись и чтение через Task.detached(priority:   
  .utility)                  
  - Keychain: KeychainHelper с @discardableResult, логирует OSStatus при ошибке
                                                                                
  ---
                                                                                
  ## Секреты                 
                                         
  Secrets enum внутри APIConfig.swift:                                        

  \```swift
  enum Secrets {
      static let apphudAPIKey = "..."
      static let backendToken = "..."
  }                                                                             
  \```
                                                                                
  Перед выкладкой в публичный репо нужно вынести в .xcconfig + environment
  variables на CI.                       
                                                                              
  ---

  ## Design System

  - AppColors: семантические цвета (background, cardBackground,                 
  textPrimary/Secondary, separatorColor, градиенты)
  - AppFonts: типографика через .system (title1, headline, body, caption,       
  captionSmall)              
  - Переиспользуемые компоненты: AIToolCard, GradientButton, MessageBubble,
  SpinnerView                                                                   
   
  ---                                                                           
                             
  ## Paywall UI                          
                                                                              
  Кастомный fullscreen paywall без ApphudUI. Анимированный фон из блюр-эллипсов,
   кнопка закрытия появляется через 2 сек, карточки тарифов с градиентной рамкой
   при выборе, авто-закрытие при hasActiveSubscription = true через onChange.   
                             
