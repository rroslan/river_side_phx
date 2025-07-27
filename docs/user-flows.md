# River Side Food Court - User Flow Documentation

## Overview

This document describes the user flows for the three main user types in the River Side Food Court system: Customers, Vendors, and Cashiers. The system uses a QR code-based table ordering system with real-time order tracking.

## System Architecture Overview

```mermaid
graph TB
    subgraph "Food Court Physical Space"
        T1[Table 1<br/>QR Code]
        T2[Table 2<br/>QR Code]
        T3[Table N<br/>QR Code]
    end
    
    subgraph "Users"
        C[Customer]
        V[Vendor Staff]
        CA[Cashier]
        A[Admin]
    end
    
    subgraph "System"
        W[Web Application]
        DB[(Database)]
        PS[PubSub<br/>Real-time]
        E[Email Service]
    end
    
    C -->|Scans QR| T1
    T1 -->|Check-in| W
    V -->|Manages Orders| W
    CA -->|Processes Payments| W
    A -->|System Control| W
    W <--> DB
    W <--> PS
    W --> E
```

## 1. Customer Flow

### 1.1 Complete Customer Journey

```mermaid
flowchart TD
    Start([Customer Enters Food Court])
    
    Start --> FindTable[Find Available Table]
    FindTable --> ScanQR[Scan QR Code on Table]
    
    ScanQR --> CheckIn{Check-in Page}
    CheckIn --> EnterPhone[Enter Phone Number]
    EnterPhone --> EnterName[Enter Name - Optional]
    EnterName --> ConfirmCheckIn[Confirm Check-in]
    
    ConfirmCheckIn --> TableOccupied[Table Status: Occupied]
    TableOccupied --> ViewMenu[View Menu Page]
    
    ViewMenu --> SelectVendor[Select Vendor Tab]
    SelectVendor --> BrowseItems[Browse Menu Items]
    BrowseItems --> SelectItem{Select Item?}
    
    SelectItem -->|Yes| AddToCart[Add to Cart]
    AddToCart --> MoreItems{Add More Items?}
    MoreItems -->|Yes| SelectVendor
    MoreItems -->|No| ViewCart[View Cart]
    
    SelectItem -->|No| MoreVendors{Browse Other Vendors?}
    MoreVendors -->|Yes| SelectVendor
    MoreVendors -->|No| ViewCart
    
    ViewCart --> ReviewOrder[Review Order Details]
    ReviewOrder --> PlaceOrder[Place Order]
    
    PlaceOrder --> OrderCreated[Order Created<br/>Status: Pending]
    OrderCreated --> TrackOrder[Order Tracking Page]
    
    TrackOrder --> WaitVendor[Wait for Vendor Accept]
    WaitVendor --> OrderPreparing[Status: Preparing]
    OrderPreparing --> OrderReady[Status: Ready]
    
    OrderReady --> GoToCashier[Go to Cashier Counter]
    GoToCashier --> ShowOrderNumber[Show Order Number]
    ShowOrderNumber --> PayCashier[Pay at Counter]
    PayCashier --> OrderPaid[Status: Paid]
    
    OrderPaid --> CollectFood[Collect Food from Vendor]
    CollectFood --> OrderCompleted[Status: Completed]
    
    OrderCompleted --> ContinueDining{Continue Dining?}
    ContinueDining -->|Order More| ViewMenu
    ContinueDining -->|Finish| CheckOut[Check Out]
    CheckOut --> TableAvailable[Table Released]
    TableAvailable --> End([Leave Food Court])
```

### 1.2 Customer State Transitions

```mermaid
stateDiagram-v2
    [*] --> NotCheckedIn
    NotCheckedIn --> CheckedIn: Scan QR + Enter Details
    
    CheckedIn --> Browsing: View Menu
    Browsing --> Shopping: Add Items
    Shopping --> Browsing: Continue Shopping
    Shopping --> Ordering: Place Order
    
    Ordering --> Tracking: Order Confirmed
    Tracking --> Paying: Order Ready
    Paying --> Collecting: Payment Complete
    Collecting --> Dining: Food Collected
    
    Dining --> Shopping: Order More
    Dining --> CheckedOut: Finish Dining
    CheckedOut --> [*]
```

## 2. Vendor Flow

### 2.1 Vendor Operations Flow

```mermaid
flowchart TD
    VStart([Vendor Staff Login])
    
    VStart --> VLogin[Login with Magic Link]
    VLogin --> VDashboard[Vendor Dashboard]
    
    VDashboard --> ManageMenu{Manage Menu?}
    ManageMenu -->|Yes| MenuOps[Menu Operations]
    MenuOps --> AddItem[Add New Item]
    MenuOps --> EditItem[Edit Item]
    MenuOps --> ToggleAvail[Toggle Availability]
    MenuOps --> VDashboard
    
    ManageMenu -->|No| MonitorOrders[Monitor Orders]
    
    MonitorOrders --> NewOrder{New Order Alert}
    NewOrder --> ViewOrder[View Order Details]
    ViewOrder --> AcceptOrder{Accept Order?}
    
    AcceptOrder -->|Yes| StartPreparing[Mark as Preparing]
    StartPreparing --> PrepareFood[Prepare Food]
    PrepareFood --> MarkReady[Mark as Ready]
    MarkReady --> WaitCustomer[Wait for Customer]
    WaitCustomer --> HandOver[Hand Over Food]
    HandOver --> MarkComplete[Mark as Completed]
    
    AcceptOrder -->|No| CancelOrder[Cancel Order]
    CancelOrder --> NotifyCustomer[Customer Notified]
    
    MarkComplete --> MonitorOrders
    NotifyCustomer --> MonitorOrders
```

### 2.2 Vendor Order State Management

```mermaid
stateDiagram-v2
    [*] --> Pending: New Order Received
    
    Pending --> Preparing: Accept Order
    Pending --> Cancelled: Reject Order
    
    Preparing --> Ready: Food Prepared
    Preparing --> Cancelled: Cannot Fulfill
    
    Ready --> Completed: Customer Collected
    Ready --> Cancelled: Customer No Show
    
    Cancelled --> [*]
    Completed --> [*]
```

## 3. Cashier Flow

### 3.1 Cashier Payment Processing Flow

```mermaid
flowchart TD
    CStart([Cashier Login])
    
    CStart --> CLogin[Login with Magic Link]
    CLogin --> CDashboard[Cashier Dashboard]
    
    CDashboard --> ViewPending[View Pending Payments]
    ViewPending --> CustomerArrives{Customer Arrives}
    
    CustomerArrives --> VerifyOrder[Verify Order Number]
    VerifyOrder --> DisplayAmount[Display Total Amount]
    DisplayAmount --> ProcessPayment{Process Payment}
    
    ProcessPayment -->|Cash| AcceptCash[Accept Cash]
    ProcessPayment -->|Card| ProcessCard[Process Card]
    ProcessPayment -->|E-Wallet| ProcessEWallet[Process E-Wallet]
    
    AcceptCash --> MarkPaid[Mark Order as Paid]
    ProcessCard --> MarkPaid
    ProcessEWallet --> MarkPaid
    
    MarkPaid --> PrintReceipt[Print Receipt]
    PrintReceipt --> NotifyVendor[Vendor Notified]
    NotifyVendor --> NextCustomer[Ready for Next Customer]
    NextCustomer --> ViewPending
```

### 3.2 Payment State Flow

```mermaid
stateDiagram-v2
    [*] --> Unpaid: Order Ready
    Unpaid --> Processing: Customer at Counter
    Processing --> Paid: Payment Successful
    Processing --> Failed: Payment Failed
    Failed --> Processing: Retry Payment
    Paid --> [*]
```

## 4. Real-time Communication Flow

### 4.1 PubSub Event Flow

```mermaid
flowchart LR
    subgraph "Customer Actions"
        CO[Place Order]
        CC[Cancel Order]
    end
    
    subgraph "PubSub Topics"
        VOT[vendor:order_topic]
        COT[customer:order_topic]
        CAT[cashier:payment_topic]
    end
    
    subgraph "Vendor Actions"
        VA[Accept Order]
        VP[Mark Preparing]
        VR[Mark Ready]
        VC[Mark Complete]
    end
    
    subgraph "Cashier Actions"
        CP[Process Payment]
    end
    
    CO --> VOT
    CC --> VOT
    VOT --> VendorLive[Vendor Dashboard]
    
    VA --> COT
    VP --> COT
    VR --> COT
    VR --> CAT
    VC --> COT
    COT --> CustomerLive[Customer Tracking]
    
    CP --> COT
    CP --> VOT
    CAT --> CashierLive[Cashier Dashboard]
```

## 5. Authentication Flow

### 5.1 Magic Link Authentication

```mermaid
flowchart TD
    Start([User Clicks Login])
    
    Start --> EnterEmail[Enter Email Address]
    EnterEmail --> RequestLink[Request Magic Link]
    RequestLink --> GenerateToken[Generate Secure Token]
    GenerateToken --> SaveToken[Save Token to DB<br/>20 min expiry]
    SaveToken --> SendEmail[Send Email with Link]
    
    SendEmail --> UserEmail[User Receives Email]
    UserEmail --> ClickLink[Click Magic Link]
    ClickLink --> ValidateToken{Token Valid?}
    
    ValidateToken -->|Yes| CreateSession[Create User Session]
    CreateSession --> DeleteToken[Delete Used Token]
    DeleteToken --> DisconnectOther[Disconnect Other Sessions]
    DisconnectOther --> RedirectDashboard[Redirect to Dashboard]
    
    ValidateToken -->|No| ShowError[Show Error Message]
    ShowError --> Start
    
    RedirectDashboard --> RoleCheck{Check User Role}
    RoleCheck -->|Admin| AdminDash[Admin Dashboard]
    RoleCheck -->|Vendor| VendorDash[Vendor Dashboard]
    RoleCheck -->|Cashier| CashierDash[Cashier Dashboard]
    RoleCheck -->|Customer| HomePage[Home Page]
```

## 6. Order Lifecycle

### 6.1 Complete Order Flow

```mermaid
flowchart TD
    subgraph "Customer Phase"
        CreateOrder[Create Order]
        AddItems[Add Order Items]
        SubmitOrder[Submit Order]
    end
    
    subgraph "Vendor Phase"
        ReceiveOrder[Receive Order Alert]
        AcceptOrder[Accept Order]
        PrepareOrder[Prepare Food]
        ReadyOrder[Mark Ready]
    end
    
    subgraph "Payment Phase"
        CustomerToCashier[Customer to Cashier]
        ProcessPayment[Process Payment]
        ConfirmPayment[Confirm Payment]
    end
    
    subgraph "Completion Phase"
        CustomerToVendor[Customer to Vendor]
        CollectFood[Collect Food]
        CompleteOrder[Mark Complete]
    end
    
    CreateOrder --> AddItems
    AddItems --> SubmitOrder
    SubmitOrder --> ReceiveOrder
    ReceiveOrder --> AcceptOrder
    AcceptOrder --> PrepareOrder
    PrepareOrder --> ReadyOrder
    ReadyOrder --> CustomerToCashier
    CustomerToCashier --> ProcessPayment
    ProcessPayment --> ConfirmPayment
    ConfirmPayment --> CustomerToVendor
    CustomerToVendor --> CollectFood
    CollectFood --> CompleteOrder
```

### 6.2 Order Status Transitions

```mermaid
stateDiagram-v2
    [*] --> Pending: Order Created
    
    Pending --> Preparing: Vendor Accepts
    Pending --> Cancelled: Vendor Rejects
    Pending --> Cancelled: Customer Cancels
    
    Preparing --> Ready: Food Prepared
    Preparing --> Cancelled: Cannot Complete
    
    Ready --> Ready_Paid: Payment Processed
    Ready --> Cancelled: Timeout/No Show
    
    Ready_Paid --> Completed: Food Collected
    Ready_Paid --> Cancelled: Not Collected
    
    Cancelled --> [*]
    Completed --> [*]
```

## 7. Error Handling Flows

### 7.1 Common Error Scenarios

```mermaid
flowchart TD
    subgraph "Table Errors"
        TableOccupied[Table Already Occupied]
        TableNotFound[Invalid QR Code]
    end
    
    subgraph "Order Errors"
        ItemUnavailable[Menu Item Unavailable]
        VendorClosed[Vendor Not Active]
        OrderTimeout[Order Timeout]
    end
    
    subgraph "Payment Errors"
        PaymentFailed[Payment Failed]
        OrderNotFound[Order Not Found]
    end
    
    subgraph "Recovery Actions"
        RetryCheckIn[Select Different Table]
        UpdateCart[Remove Unavailable Items]
        ResubmitOrder[Create New Order]
        RetryPayment[Try Different Payment Method]
        ContactSupport[Contact Staff]
    end
    
    TableOccupied --> RetryCheckIn
    TableNotFound --> ContactSupport
    
    ItemUnavailable --> UpdateCart
    VendorClosed --> UpdateCart
    OrderTimeout --> ResubmitOrder
    
    PaymentFailed --> RetryPayment
    OrderNotFound --> ContactSupport
```

## 8. Administrative Flows

### 8.1 Admin System Management

```mermaid
flowchart TD
    AStart([Admin Login])
    
    AStart --> ADashboard[Admin Dashboard]
    
    ADashboard --> UserMgmt{User Management}
    UserMgmt --> CreateUser[Create User]
    UserMgmt --> EditUser[Edit User]
    UserMgmt --> DeleteUser[Delete User]
    UserMgmt --> AssignRoles[Assign Roles]
    
    ADashboard --> VendorMgmt{Vendor Management}
    VendorMgmt --> CreateVendor[Create Vendor]
    VendorMgmt --> EditVendor[Edit Vendor]
    VendorMgmt --> DeleteVendor[Delete Vendor]
    
    ADashboard --> SystemOps{System Operations}
    SystemOps --> ResetTables[Reset All Tables]
    SystemOps --> ViewReports[View Reports]
    SystemOps --> SystemConfig[System Configuration]
    
    CreateUser --> SendMagicLink[Send Login Link]
    DeleteVendor --> CascadeDelete[Cascade Delete Orders/Items]
    ResetTables --> ReleaseAllTables[Release All Tables]
```

## 9. Data Flow Summary

### 9.1 Key Data Relationships

```mermaid
erDiagram
    USER ||--o{ ORDER : places
    USER ||--o| VENDOR : manages
    VENDOR ||--o{ MENU_ITEM : has
    VENDOR ||--o{ ORDER : receives
    ORDER ||--o{ ORDER_ITEM : contains
    ORDER_ITEM }o--|| MENU_ITEM : references
    TABLE ||--o{ ORDER : hosts
    USER ||--o{ TABLE : occupies
    
    USER {
        id uuid
        email string
        role string
        is_vendor boolean
        is_admin boolean
        is_cashier boolean
    }
    
    VENDOR {
        id uuid
        name string
        description text
        is_active boolean
        user_id uuid
    }
    
    ORDER {
        id uuid
        status string
        total decimal
        customer_name string
        customer_phone string
        table_number integer
        paid boolean
    }
    
    TABLE {
        id uuid
        number integer
        status string
        customer_phone string
        cart_data jsonb
    }
```

## Best Practices

### For Customers
1. Always check out when leaving to free the table
2. Keep order number handy for payment
3. Monitor order status for timely collection

### For Vendors
1. Accept/reject orders promptly
2. Update order status accurately
3. Keep menu items availability current

### For Cashiers
1. Verify order details before payment
2. Ensure receipt is provided
3. Handle payment failures gracefully

### For Admins
1. Regular monitoring of system health
2. Prompt user support for issues
3. Maintain data integrity with cascade operations