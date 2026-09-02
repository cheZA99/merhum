using MerhumAPI.Models;

namespace MerhumAPI.Common;

// allowed status transitions, kept in one place so services cannot invent their own
public static class StatusTransitions
{
    private static readonly Dictionary<AppointmentStatus, AppointmentStatus[]> Appointment = new()
    {
        [AppointmentStatus.Scheduled] = new[] { AppointmentStatus.Held, AppointmentStatus.Cancelled },
        [AppointmentStatus.Held] = Array.Empty<AppointmentStatus>(),
        [AppointmentStatus.Cancelled] = Array.Empty<AppointmentStatus>()
    };

    private static readonly Dictionary<ServiceOrderStatus, ServiceOrderStatus[]> ServiceOrder = new()
    {
        [ServiceOrderStatus.Ordered] = new[] { ServiceOrderStatus.InProgress, ServiceOrderStatus.Cancelled },
        [ServiceOrderStatus.InProgress] = new[] { ServiceOrderStatus.Completed, ServiceOrderStatus.Cancelled },
        [ServiceOrderStatus.Completed] = Array.Empty<ServiceOrderStatus>(),
        [ServiceOrderStatus.Cancelled] = Array.Empty<ServiceOrderStatus>()
    };

    public static bool AppointmentAllows(AppointmentStatus from, AppointmentStatus to) =>
        Appointment.TryGetValue(from, out var allowed) && allowed.Contains(to);

    public static bool ServiceOrderAllows(ServiceOrderStatus from, ServiceOrderStatus to) =>
        ServiceOrder.TryGetValue(from, out var allowed) && allowed.Contains(to);

    // the procedure moves one phase at a time, in the order given by SortOrder
    public static bool ProcedureAllows(int fromSortOrder, int toSortOrder) => toSortOrder == fromSortOrder + 1;
}
